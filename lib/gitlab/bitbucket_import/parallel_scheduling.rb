# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module ParallelScheduling
      include Loggable
      include ErrorTracking

      attr_reader :project, :already_enqueued_cache_key, :job_waiter_cache_key, :job_waiter_remaining_cache_key,
        :page_keyset

      # The base cache key to use for tracking already enqueued objects.
      ALREADY_ENQUEUED_CACHE_KEY =
        'bitbucket-importer/already-enqueued/%{project}/%{collection}'

      # The base cache key to use for storing job waiter key
      JOB_WAITER_CACHE_KEY =
        'bitbucket-importer/job-waiter/%{project}/%{collection}'

      # The base cache key to use for storing job waiter remaining jobs
      JOB_WAITER_REMAINING_CACHE_KEY =
        'bitbucket-importer/job-waiter-remaining/%{project}/%{collection}'

      # project - An instance of `Project`.
      def initialize(project)
        @project = project

        @already_enqueued_cache_key =
          format(ALREADY_ENQUEUED_CACHE_KEY, project: project.id, collection: collection_method)
        @job_waiter_cache_key =
          format(JOB_WAITER_CACHE_KEY, project: project.id, collection: collection_method)
        @job_waiter_remaining_cache_key = format(JOB_WAITER_REMAINING_CACHE_KEY, project: project.id,
          collection: collection_method)
        @page_keyset = Gitlab::Import::PageKeyset.new(project, collection_method, 'bitbucket-importer')
      end

      # The method that will be called for traversing through all the objects to
      # import, yielding them to the supplied block.
      def each_object_to_import
        repo = project.import_source

        options = collection_options.merge(next_url: page_keyset.current)

        client.each_page(collection_method, representation_type, repo, options) do |page|
          page.items.each do |object|
            job_waiter.jobs_remaining = Gitlab::Cache::Import::Caching.increment(job_waiter_remaining_cache_key)

            object = object.to_hash

            next if already_enqueued?(object)

            yield object

            # We mark the object as imported immediately so we don't end up
            # scheduling it multiple times.
            mark_as_enqueued(object)
          end

          page_keyset.set(page.next) if page.next?
        end
      end

      private

      # Any options to be passed to the method used for retrieving the data to
      # import.
      def collection_options
        {}
      end

      def client
        @client ||= Bitbucket::Client.new(project.import_data.credentials)
      end

      # Returns the ID to use for the cache used for checking if an object has
      # already been enqueued or not.
      #
      # object - The object we may want to import.
      def id_for_already_enqueued_cache(object)
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

      # The name of the method to call to retrieve the representation object
      def representation_type
        raise NotImplementedError
      end

      def job_waiter
        @job_waiter ||= begin
          key = Gitlab::Cache::Import::Caching.read(job_waiter_cache_key)
          key ||= Gitlab::Cache::Import::Caching.write(job_waiter_cache_key, JobWaiter.generate_key)
          jobs_remaining = Gitlab::Cache::Import::Caching.read(job_waiter_remaining_cache_key).to_i || 0

          JobWaiter.new(jobs_remaining, key)
        end
      end

      def already_enqueued?(object)
        id = id_for_already_enqueued_cache(object)

        Gitlab::Cache::Import::Caching.set_includes?(already_enqueued_cache_key, id)
      end

      # Marks the given object as "already enqueued".
      def mark_as_enqueued(object)
        id = id_for_already_enqueued_cache(object)

        Gitlab::Cache::Import::Caching.set_add(already_enqueued_cache_key, id)
      end

      def calculate_job_delay(job_index)
        runtime = Time.current - job_started_at
        multiplier = (job_index / concurrent_import_jobs_limit.to_f)

        (multiplier * 1.minute) + 1.second - runtime
      end

      def job_started_at
        @job_started_at ||= Time.current
      end

      def concurrent_import_jobs_limit
        Gitlab::CurrentSettings.concurrent_bitbucket_import_jobs_limit
      end
    end
  end
end
