# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module ParallelScheduling
      include Loggable

      attr_reader :project, :already_processed_cache_key, :job_waiter_cache_key

      # The base cache key to use for tracking already processed objects.
      ALREADY_PROCESSED_CACHE_KEY =
        'bitbucket-server-importer/already-processed/%{project}/%{collection}'

      # The base cache key to use for storing job waiter key
      JOB_WAITER_CACHE_KEY =
        'bitbucket-server-importer/job-waiter/%{project}/%{collection}'

      BATCH_SIZE = 100

      # project - An instance of `Project`.
      def initialize(project)
        @project = project

        @already_processed_cache_key =
          format(ALREADY_PROCESSED_CACHE_KEY, project: project.id, collection: collection_method)
        @job_waiter_cache_key =
          format(JOB_WAITER_CACHE_KEY, project: project.id, collection: collection_method)
      end

      private

      def client
        @client ||= BitbucketServer::Client.new(project.import_data.credentials)
      end

      def project_key
        @project_key ||= project.import_data.data['project_key']
      end

      def repository_slug
        @repository_slug ||= project.import_data.data['repo_slug']
      end

      # Returns the ID to use for the cache used for checking if an object has
      # already been processed or not.
      #
      # object - The object we may want to import.
      def id_for_already_processed_cache(object)
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

      def job_waiter
        @job_waiter ||= begin
          key = Gitlab::Cache::Import::Caching.read(job_waiter_cache_key)
          key ||= Gitlab::Cache::Import::Caching.write(job_waiter_cache_key, JobWaiter.generate_key)

          JobWaiter.new(0, key)
        end
      end

      def already_processed?(object)
        id = id_for_already_processed_cache(object)

        Gitlab::Cache::Import::Caching.set_includes?(already_processed_cache_key, id)
      end

      # Marks the given object as "already processed".
      def mark_as_processed(object)
        id = id_for_already_processed_cache(object)

        Gitlab::Cache::Import::Caching.set_add(already_processed_cache_key, id)
      end

      def calculate_job_delay(job_index)
        multiplier = (job_index / BATCH_SIZE)

        (multiplier * 1.minute) + 1.second
      end

      def track_import_failure!(project, exception:, **args)
        Gitlab::Import::ImportFailureService.track(
          project_id: project.id,
          error_source: self.class.name,
          exception: exception,
          **args
        )
      end
    end
  end
end
