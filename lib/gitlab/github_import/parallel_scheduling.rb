# frozen_string_literal: true

module Gitlab
  module GithubImport
    module ParallelScheduling
      attr_reader :project, :client, :page_counter, :already_imported_cache_key

      # The base cache key to use for tracking already imported objects.
      ALREADY_IMPORTED_CACHE_KEY =
        'github-importer/already-imported/%{project}/%{collection}'

      # project - An instance of `Project`.
      # client - An instance of `Gitlab::GithubImport::Client`.
      # parallel - When set to true the objects will be imported in parallel.
      def initialize(project, client, parallel: true)
        @project = project
        @client = client
        @parallel = parallel
        @page_counter = PageCounter.new(project, collection_method)
        @already_imported_cache_key = ALREADY_IMPORTED_CACHE_KEY %
          { project: project.id, collection: collection_method }
      end

      def parallel?
        @parallel
      end

      def execute
        info(project.id, message: "starting importer")

        retval =
          if parallel?
            parallel_import
          else
            sequential_import
          end

        # Once we have completed all work we can remove our "already exists"
        # cache so we don't put too much pressure on Redis.
        #
        # We don't immediately remove it since it's technically possible for
        # other instances of this job to still run, instead we set the
        # expiration time to a lower value. This prevents the other jobs from
        # still scheduling duplicates while. Since all work has already been
        # completed those jobs will just cycle through any remaining pages while
        # not scheduling anything.
        Gitlab::Cache::Import::Caching.expire(already_imported_cache_key, 15.minutes.to_i)
        info(project.id, message: "importer finished")

        retval
      rescue StandardError => e
        error(project.id, e)

        raise e
      end

      # Imports all the objects in sequence in the current thread.
      def sequential_import
        each_object_to_import do |object|
          repr = representation_class.from_api_response(object)

          importer_class.new(repr, project, client).execute
        end
      end

      # Imports all objects in parallel by scheduling a Sidekiq job for every
      # individual object.
      def parallel_import
        waiter = JobWaiter.new

        each_object_to_import do |object|
          repr = representation_class.from_api_response(object)

          sidekiq_worker_class
            .perform_async(project.id, repr.to_hash, waiter.key)

          waiter.jobs_remaining += 1
        end

        waiter
      end

      # The method that will be called for traversing through all the objects to
      # import, yielding them to the supplied block.
      def each_object_to_import
        repo = project.import_source

        # We inject the page number here to make sure that all importers always
        # start where they left off. Simply starting over wouldn't work for
        # repositories with a lot of data (e.g. tens of thousands of comments).
        options = collection_options.merge(page: page_counter.current)

        client.each_page(collection_method, repo, options) do |page|
          # Technically it's possible that the same work is performed multiple
          # times, as Sidekiq doesn't guarantee there will ever only be one
          # instance of a job. In such a scenario it's possible for one job to
          # have a lower page number (e.g. 5) compared to another (e.g. 10). In
          # this case we skip over all the objects until we have caught up,
          # reducing the number of duplicate jobs scheduled by the provided
          # block.
          next unless page_counter.set(page.number)

          page.objects.each do |object|
            next if already_imported?(object)

            Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)

            yield object

            # We mark the object as imported immediately so we don't end up
            # scheduling it multiple times.
            mark_as_imported(object)
          end
        end
      end

      # Returns true if the given object has already been imported, false
      # otherwise.
      #
      # object - The object to check.
      def already_imported?(object)
        id = id_for_already_imported_cache(object)

        Gitlab::Cache::Import::Caching.set_includes?(already_imported_cache_key, id)
      end

      # Marks the given object as "already imported".
      def mark_as_imported(object)
        id = id_for_already_imported_cache(object)

        Gitlab::Cache::Import::Caching.set_add(already_imported_cache_key, id)
      end

      def object_type
        raise NotImplementedError
      end

      # Returns the ID to use for the cache used for checking if an object has
      # already been imported or not.
      #
      # object - The object we may want to import.
      def id_for_already_imported_cache(object)
        raise NotImplementedError
      end

      # The class used for converting API responses to Hashes when performing
      # the import.
      def representation_class
        raise NotImplementedError
      end

      # The class to use for importing objects when importing them sequentially.
      def importer_class
        raise NotImplementedError
      end

      # The Sidekiq worker class used for scheduling the importing of objects in
      # parallel.
      def sidekiq_worker_class
        raise NotImplementedError
      end

      # The name of the method to call to retrieve the data to import.
      def collection_method
        raise NotImplementedError
      end

      # Any options to be passed to the method used for retrieving the data to
      # import.
      def collection_options
        {}
      end

      private

      def info(project_id, extra = {})
        logger.info(log_attributes(project_id, extra))
      end

      def error(project_id, exception)
        logger.error(
          log_attributes(
            project_id,
            message: 'importer failed',
            'error.message': exception.message
          )
        )

        Gitlab::ErrorTracking.track_exception(
          exception,
          log_attributes(project_id)
        )
      end

      def log_attributes(project_id, extra = {})
        extra.merge(
          import_source: :github,
          project_id: project_id,
          importer: importer_class.name,
          parallel: parallel?
        )
      end

      def logger
        @logger ||= Gitlab::Import::Logger.build
      end
    end
  end
end
