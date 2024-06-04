# frozen_string_literal: true

module Gitlab
  module Import
    module AdvanceStage
      extend ActiveSupport::Concern

      INTERVAL = 30.seconds.to_i
      TIMEOUT_DURATION = 2.hours

      AdvanceStageTimeoutError = Class.new(StandardError)

      # The number of seconds to wait (while blocking the thread) before
      # continuing to the next waiter.
      BLOCKING_WAIT_TIME = 5

      included do
        sidekiq_options dead: false, retry: 6
        feature_category :importers
      end

      # project_id - The ID of the project being imported.
      # waiters - A Hash mapping Gitlab::JobWaiter keys to the number of
      #           remaining jobs.
      # next_stage - The name of the next stage to start when all jobs have been
      #              completed.
      # timeout_timer - Time the sidekiq worker was first initiated with the current job_count
      # previous_job_count - Number of jobs remaining on last invocation of this worker
      def perform(project_id, waiters, next_stage, timeout_timer = Time.zone.now.to_s, previous_job_count = nil)
        import_state_jid = find_import_state_jid(project_id)

        # If the import state is nil the project may have been deleted or the import
        # may have failed or been canceled. In this case we tidy up the cache data and no
        # longer attempt to advance to the next stage.
        if import_state_jid.nil?
          clear_waiter_caches(waiters)
          return
        end

        new_waiters = wait_for_jobs(waiters)
        new_job_count = new_waiters.values.sum

        # Reset the timeout timer as some jobs finished processing
        if new_job_count != previous_job_count
          timeout_timer = Time.zone.now
          previous_job_count = new_job_count

          import_state_jid.refresh_jid_expiration
        end

        if new_waiters.empty?
          proceed_to_next_stage(import_state_jid, next_stage, project_id)
        elsif timeout_reached?(timeout_timer) && new_job_count == previous_job_count

          handle_timeout(import_state_jid, next_stage, project_id, new_waiters, new_job_count)
        else
          self.class.perform_in(INTERVAL,
            project_id, new_waiters.deep_stringify_keys, next_stage.to_s, timeout_timer.to_s, previous_job_count
          )
        end
      end

      def wait_for_jobs(waiters)
        waiters.each_with_object({}) do |(key, remaining), new_waiters|
          waiter = JobWaiter.new(remaining, key)

          # We wait for a brief moment of time so we don't reschedule if we can
          # complete the work fast enough.
          waiter.wait(BLOCKING_WAIT_TIME)

          next unless waiter.jobs_remaining > 0

          new_waiters[waiter.key] = waiter.jobs_remaining
        end
      end

      def find_import_state_jid(project_id)
        raise NotImplementedError
      end

      def find_import_state(id)
        raise NotImplementedError
      end

      private

      def proceed_to_next_stage(import_state_jid, next_stage, project_id)
        # We refresh the import JID here so workers importing individual
        # resources (e.g. notes) don't have to do this all the time, reducing
        # the pressure on Redis. We _only_ do this once all jobs are done so
        # we don't get stuck forever if one or more jobs failed to notify the
        # JobWaiter.
        import_state_jid.refresh_jid_expiration

        next_stage_worker(next_stage).perform_async(project_id)
      end

      def handle_timeout(import_state_jid, next_stage, project_id, new_waiters, new_job_count)
        project = Project.find_by_id(project_id)
        strategy = project.import_data&.data&.dig("timeout_strategy") || ProjectImportData::PESSIMISTIC_TIMEOUT

        ::Import::Framework::Logger.info(
          message: 'Timeout reached, no longer retrying',
          project_id: project_id,
          jobs_remaining: new_job_count,
          waiters: new_waiters,
          timeout_strategy: strategy
        )

        clear_waiter_caches(new_waiters)

        case strategy
        when ProjectImportData::OPTIMISTIC_TIMEOUT
          proceed_to_next_stage(import_state_jid, next_stage, project_id)
        when ProjectImportData::PESSIMISTIC_TIMEOUT
          import_state = find_import_state(import_state_jid.id)
          fail_import_and_log_status(import_state)
        end
      end

      def fail_import_and_log_status(import_state)
        raise AdvanceStageTimeoutError, "Failing advance stage, timeout reached with pessimistic strategy"
      rescue AdvanceStageTimeoutError => e
        Gitlab::Import::ImportFailureService.track(
          import_state: import_state,
          exception: e,
          error_source: self.class.name,
          fail_import: true
        )
      end

      def timeout_reached?(timeout_timer)
        timeout_timer = Time.zone.parse(timeout_timer) if timeout_timer.is_a?(String)
        Time.zone.now > timeout_timer + TIMEOUT_DURATION
      end

      def next_stage_worker(next_stage)
        raise NotImplementedError
      end

      def clear_waiter_caches(waiters)
        waiters.each_key do |key|
          JobWaiter.delete_key(key)
        end
      end
    end
  end
end
