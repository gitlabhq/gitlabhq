# frozen_string_literal: true

module Gitlab
  module GithubImport
    class RefreshImportJidWorker
      include ApplicationWorker
      include GithubImport::Queue

      # The interval to schedule new instances of this job at.
      INTERVAL = 1.minute.to_i

      def self.perform_in_the_future(*args)
        perform_in(INTERVAL, *args)
      end

      # project_id - The ID of the project that is being imported.
      # check_job_id - The ID of the job for which to check the status.
      def perform(project_id, check_job_id)
        return unless (project = find_project(project_id))

        if SidekiqStatus.running?(check_job_id)
          # As long as the repository is being cloned we want to keep refreshing
          # the import JID status.
          project.refresh_import_jid_expiration
          self.class.perform_in_the_future(project_id, check_job_id)
        end

        # If the job is no longer running there's nothing else we need to do. If
        # the clone job completed successfully it will have scheduled the next
        # stage, if it died there's nothing we can do anyway.
      end

      def find_project(id)
        Project.select(:import_jid).import_started.find_by(id: id)
      end
    end
  end
end
