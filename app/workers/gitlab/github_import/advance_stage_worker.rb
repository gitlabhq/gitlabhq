# frozen_string_literal: true

module Gitlab
  module GithubImport
    # AdvanceStageWorker is a worker used by the GitHub importer to wait for a
    # number of jobs to complete, without blocking a thread. Once all jobs have
    # been completed this worker will advance the import process to the next
    # stage.
    class AdvanceStageWorker
      include ApplicationWorker

      sidekiq_options dead: false

      INTERVAL = 30.seconds.to_i

      # The number of seconds to wait (while blocking the thread) before
      # continueing to the next waiter.
      BLOCKING_WAIT_TIME = 5

      # The known importer stages and their corresponding Sidekiq workers.
      STAGES = {
        issues_and_diff_notes: Stage::ImportIssuesAndDiffNotesWorker,
        notes: Stage::ImportNotesWorker,
        finish: Stage::FinishImportWorker
      }.freeze

      # project_id - The ID of the project being imported.
      # waiters - A Hash mapping Gitlab::JobWaiter keys to the number of
      #           remaining jobs.
      # next_stage - The name of the next stage to start when all jobs have been
      #              completed.
      def perform(project_id, waiters, next_stage)
        return unless (project = find_project(project_id))

        new_waiters = wait_for_jobs(waiters)

        if new_waiters.empty?
          # We refresh the import JID here so workers importing individual
          # resources (e.g. notes) don't have to do this all the time, reducing
          # the pressure on Redis. We _only_ do this once all jobs are done so
          # we don't get stuck forever if one or more jobs failed to notify the
          # JobWaiter.
          project.refresh_import_jid_expiration

          STAGES.fetch(next_stage.to_sym).perform_async(project_id)
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

          next unless waiter.jobs_remaining.positive?

          new_waiters[waiter.key] = waiter.jobs_remaining
        end
      end

      def find_project(id)
        # We only care about the import JID so we can refresh it. We also only
        # want the project if it hasn't been marked as failed yet. It's possible
        # the import gets marked as stuck when jobs of the current stage failed
        # somehow.
        Project.select(:import_jid).import_started.find_by(id: id)
      end
    end
  end
end
