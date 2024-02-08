# frozen_string_literal: true

module Gitlab
  module Import
    class RefreshImportJidWorker
      include ApplicationWorker

      data_consistency :delayed
      idempotent!

      feature_category :importers
      sidekiq_options dead: false

      sidekiq_options retry: 5

      # The interval to schedule new instances of this job at.
      INTERVAL = 5.minutes.to_i

      def self.perform_in_the_future(*args)
        perform_in(INTERVAL, *args)
      end

      # project_id - The ID of the project that is being imported.
      # check_job_id - The ID of the job for which to check the status.
      # params - to avoid multiple releases if parameters change
      def perform(project_id, check_job_id, _params = {})
        return unless SidekiqStatus.running?(check_job_id)

        import_state_jid = ProjectImportState.jid_by(project_id: project_id, status: :started)&.jid
        return unless import_state_jid

        # As long as the worker is running we want to keep refreshing
        # the worker's JID as well as the import's JID.
        Gitlab::SidekiqStatus.expire(check_job_id, Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION)
        Gitlab::SidekiqStatus.set(import_state_jid, Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION)

        self.class.perform_in_the_future(project_id, check_job_id)
      end
    end
  end
end
