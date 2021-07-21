# frozen_string_literal: true

module Gitlab
  module GithubImport
    class RefreshImportJidWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include GithubImport::Queue

      # The interval to schedule new instances of this job at.
      INTERVAL = 1.minute.to_i

      def self.perform_in_the_future(*args)
        perform_in(INTERVAL, *args)
      end

      # project_id - The ID of the project that is being imported.
      # check_job_id - The ID of the job for which to check the status.
      def perform(project_id, check_job_id)
        import_state = find_import_state(project_id)
        return unless import_state

        if SidekiqStatus.running?(check_job_id)
          # As long as the repository is being cloned we want to keep refreshing
          # the import JID status.
          import_state.refresh_jid_expiration
          self.class.perform_in_the_future(project_id, check_job_id)
        end

        # If the job is no longer running there's nothing else we need to do. If
        # the clone job completed successfully it will have scheduled the next
        # stage, if it died there's nothing we can do anyway.
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def find_import_state(project_id)
        ProjectImportState.select(:jid)
          .with_status(:started)
          .find_by(project_id: project_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
