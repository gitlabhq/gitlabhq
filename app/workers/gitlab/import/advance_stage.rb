# frozen_string_literal: true

module Gitlab
  module Import
    module AdvanceStage
      INTERVAL = 30.seconds.to_i

      # The number of seconds to wait (while blocking the thread) before
      # continuing to the next waiter.
      BLOCKING_WAIT_TIME = 5

      # project_id - The ID of the project being imported.
      # waiters - A Hash mapping Gitlab::JobWaiter keys to the number of
      #           remaining jobs.
      # next_stage - The name of the next stage to start when all jobs have been
      #              completed.
      def perform(project_id, waiters, next_stage)
        return unless import_state = find_import_state(project_id)

        new_waiters = wait_for_jobs(waiters)

        if new_waiters.empty?
          # We refresh the import JID here so workers importing individual
          # resources (e.g. notes) don't have to do this all the time, reducing
          # the pressure on Redis. We _only_ do this once all jobs are done so
          # we don't get stuck forever if one or more jobs failed to notify the
          # JobWaiter.
          import_state.refresh_jid_expiration

          next_stage_worker(next_stage).perform_async(project_id)
        else
          self.class.perform_in(INTERVAL, project_id, new_waiters, next_stage)
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

      def find_import_state(project_id)
        raise NotImplementedError
      end

      private

      def next_stage_worker(next_stage)
        raise NotImplementedError
      end
    end
  end
end
