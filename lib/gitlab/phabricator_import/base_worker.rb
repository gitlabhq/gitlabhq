# frozen_string_literal: true

# All workers within a Phabricator import should inherit from this worker and
# implement the `#import` method. The jobs should then be scheduled using the
# `.schedule` class method instead of `.perform_async`
#
# Doing this makes sure that only one job of that type is running at the same time
# for a certain project. This will avoid deadlocks. When a job is already running
# we'll wait for it for 10 times 5 seconds to restart. If the running job hasn't
# finished, by then, we'll retry in 30 seconds.
#
# It also makes sure that we keep the import state of the project up to date:
# - It keeps track of the jobs so we know how many jobs are running for the
#   project
# - It refreshes the import jid, so it doesn't get cleaned up by the
#   `StuckImportJobsWorker`
# - It marks the import as failed if a job failed to many times
# - It marks the import as finished when all remaining jobs are done
module Gitlab
  module PhabricatorImport
    class BaseWorker
      include ApplicationWorker
      include ProjectImportOptions # This marks the project as failed after too many tries
      include Gitlab::ExclusiveLeaseHelpers

      class << self
        def schedule(project_id, *args)
          perform_async(project_id, *args)
          add_job(project_id)
        end

        def add_job(project_id)
          worker_state(project_id).add_job
        end

        def remove_job(project_id)
          worker_state(project_id).remove_job
        end

        def worker_state(project_id)
          Gitlab::PhabricatorImport::WorkerState.new(project_id)
        end
      end

      def perform(project_id, *args)
        in_lock("#{self.class.name.underscore}/#{project_id}/#{args}", ttl: 2.hours, sleep_sec: 5.seconds) do
          project = Project.find_by_id(project_id)
          next unless project

          # Bail if the import job already failed
          next unless project.import_state&.in_progress?

          project.import_state.refresh_jid_expiration

          import(project, *args)

          # If this is the last running job, finish the import
          project.after_import if self.class.worker_state(project_id).running_count < 2

          self.class.remove_job(project_id)
        end
      rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
        # Reschedule a job if there was already a running one
        # Running them at the same time could cause a deadlock updating the same
        # resource
        self.class.perform_in(30.seconds, project_id, *args)
      end

      private

      def import(project, *args)
        importer_class.new(project, *args).execute
      end

      def importer_class
        raise NotImplementedError, "Implement `#{__method__}` on #{self.class}"
      end
    end
  end
end
