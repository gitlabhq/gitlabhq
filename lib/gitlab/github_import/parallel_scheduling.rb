# frozen_string_literal: true

module Gitlab
  module GithubImport
    module ParallelScheduling
      include JobDelayCalculator

      attr_reader :project, :client, :page_counter, :already_imported_cache_key,
        :job_waiter_cache_key, :job_waiter_remaining_cache_key

      attr_accessor :job_started_at, :enqueued_job_counter

      # The base cache key to use for tracking already imported objects.
      ALREADY_IMPORTED_CACHE_KEY =
        'github-importer/already-imported/%{project}/%{collection}'
      # The base cache key to use for storing job waiter key
      JOB_WAITER_CACHE_KEY =
        'github-importer/job-waiter/%{project}/%{collection}'
      # The base cache key to use for storing job waiter remaining jobs
      JOB_WAITER_REMAINING_CACHE_KEY =
        'github-importer/job-waiter-remaining/%{project}/%{collection}'

      # project - An instance of `Project`.
      # client - An instance of `Gitlab::GithubImport::Client`.
      # parallel - When set to true the objects will be imported in parallel.
      def initialize(project, client, parallel: true)
        @project = project
        @client = client
        @parallel = parallel
        @page_counter = Gitlab::Import::PageCounter.new(project, collection_method)
        @already_imported_cache_key = format(ALREADY_IMPORTED_CACHE_KEY, project: project.id,
          collection: collection_method)
        @job_waiter_cache_key = format(JOB_WAITER_CACHE_KEY, project: project.id, collection: collection_method)
        @job_waiter_remaining_cache_key = format(JOB_WAITER_REMAINING_CACHE_KEY, project: project.id,
          collection: collection_method)
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
        Gitlab::Cache::Import::Caching.expire(already_imported_cache_key,
          Gitlab::Cache::Import::Caching::SHORTER_TIMEOUT)
        info(project.id, message: "importer finished")

        retval
      rescue StandardError => e
        Gitlab::Import::ImportFailureService.track(
          project_id: project.id,
          error_source: self.class.name,
          exception: e,
          fail_import: abort_on_failure,
          metrics: true
        )

        raise(e)
      end

      # Imports all the objects in sequence in the current thread.
      def sequential_import
        each_object_to_import do |object|
          repr = object_representation(object)

          importer_class.new(repr, project, client).execute
        end
      end

      # Imports all objects in parallel by scheduling a Sidekiq job for every
      # individual object.
      def parallel_import
        raise 'Batch settings must be defined for parallel import' if parallel_import_batch.blank?

        spread_parallel_import
      end

      def spread_parallel_import
        self.job_started_at = Time.current
        self.enqueued_job_counter = 0

        each_object_to_import do |object|
          repr = object_representation(object)

          sidekiq_worker_class.perform_in(job_delay, project.id, repr.to_hash.deep_stringify_keys, job_waiter.key.to_s)

          self.enqueued_job_counter += 1

          job_waiter.jobs_remaining = Gitlab::Cache::Import::Caching.increment(job_waiter_remaining_cache_key)
        end

        job_waiter
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
            object = object.to_h

            next if already_imported?(object)

            if increment_object_counter?(object)
              Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)
            end

            yield object

            # We mark the object as imported immediately so we don't end up
            # scheduling it multiple times.
            mark_as_imported(object)
          end
        end
      end

      def increment_object_counter?(_object)
        true
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

      def abort_on_failure
        false
      end

      # Any options to be passed to the method used for retrieving the data to
      # import.
      def collection_options
        {}
      end

      private

      # Returns the set used to track "already imported" objects.
      # Items are the values returned by `#id_for_already_imported_cache`.
      def already_imported_ids
        Gitlab::Cache::Import::Caching.values_from_set(already_imported_cache_key)
      end

      def additional_object_data
        {}
      end

      def object_representation(object)
        representation_class.from_api_response(object, additional_object_data)
      end

      def info(project_id, extra = {})
        Logger.info(log_attributes(project_id, extra))
      end

      def log_attributes(project_id, extra = {})
        extra.merge(
          project_id: project_id,
          importer: importer_class.name,
          parallel: parallel?
        )
      end

      def job_waiter
        @job_waiter ||= begin
          key = Gitlab::Cache::Import::Caching.read(job_waiter_cache_key)
          key ||= Gitlab::Cache::Import::Caching.write(job_waiter_cache_key, JobWaiter.generate_key)
          jobs_remaining = Gitlab::Cache::Import::Caching.read(job_waiter_remaining_cache_key).to_i || 0

          JobWaiter.new(jobs_remaining, key)
        end
      end

      def job_delay
        runtime = Time.current - job_started_at

        delay = calculate_job_delay(enqueued_job_counter) - runtime

        delay > 0 ? delay : 1.0.second
      end
    end
  end
end
