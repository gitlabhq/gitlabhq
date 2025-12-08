# frozen_string_literal: true

module Gitlab
  module GithubImport
    # Module that provides methods shared by the various workers used for
    # importing GitHub projects.
    module ReschedulingMethods
      extend ActiveSupport::Concern
      include JobDelayCalculator

      attr_reader :project

      ENQUEUED_JOB_COUNT = 'github-importer/enqueued_job_count/%{project}/%{collection}'

      included do
        loggable_arguments 2
      end

      # project_id - The ID of the GitLab project to import the note into.
      # hash - A Hash containing the details of the GitHub object to import.
      # notify_key - The Redis key to notify upon completion, if any.

      def perform(project_id, hash, notify_key = nil)
        @project = Project.find_by_id(project_id) # rubocop:disable Gitlab/ModuleWithInstanceVariables -- GitHub Import
        # uses modules everywhere. Too big to refactor.

        return notify_waiter(notify_key) unless project

        client = GithubImport.new_client_for(project, parallel: true)

        import_result = try_import(project, client, hash)

        if import_result[:success]
          notify_waiter(notify_key)
        else
          reschedule_job(project, client, hash, notify_key, import_result[:reset_in])
        end
      end

      def try_import(...)
        import(...)
        { success: true }
      rescue RateLimitError => e
        { success: false, reset_in: e.reset_in }
      rescue UserFinder::FailedToObtainLockError
        { success: false, reset_in: nil }
      end

      def notify_waiter(key = nil)
        JobWaiter.notify(key, jid, ttl: Gitlab::Import::JOB_WAITER_TTL) if key
      end

      def reschedule_job(project, client, hash, notify_key, reset_in = nil)
        # In the event of hitting the rate limit we want to reschedule the job
        # so its retried after our rate limit has been reset with additional delay
        # to spread the load.
        enqueued_job_count_key = format(ENQUEUED_JOB_COUNT, project: project.id, collection: object_type)
        rate_limit_resets_in = reset_in || client.rate_limit_resets_in
        enqueued_job_counter = Gitlab::Cache::Import::Caching.increment(enqueued_job_count_key,
          timeout: [rate_limit_resets_in, Gitlab::Cache::Import::Caching::TIMEOUT].max)

        job_delay = rate_limit_resets_in + calculate_job_delay(enqueued_job_counter)

        self.class.perform_in(job_delay, project.id, hash.deep_stringify_keys, notify_key.to_s)
      end
    end
  end
end
