# frozen_string_literal: true

module ProjectExportOptions
  extend ActiveSupport::Concern

  EXPORT_RETRY_COUNT = 3

  included do
    sidekiq_options retry: EXPORT_RETRY_COUNT, status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION

    # We mark the project export as failed once we have exhausted all retries
    sidekiq_retries_exhausted do |job|
      project = Project.find(job['args'][1])
      # rubocop: disable CodeReuse/ActiveRecord
      job = project.export_jobs.find_by(jid: job["jid"])
      # rubocop: enable CodeReuse/ActiveRecord

      if job&.fail_op
        Sidekiq.logger.info "Job #{job['jid']} for project #{project.id} has been set to failed state"
      else
        Sidekiq.logger.error "Failed to set Job #{job['jid']} for project #{project.id} to failed state"
      end
    end
  end
end
