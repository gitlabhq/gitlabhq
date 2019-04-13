# frozen_string_literal: true

module ProjectImportOptions
  extend ActiveSupport::Concern

  IMPORT_RETRY_COUNT = 5

  included do
    sidekiq_options retry: IMPORT_RETRY_COUNT, status_expiration: StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION

    # We only want to mark the project as failed once we exhausted all retries
    sidekiq_retries_exhausted do |job|
      project = Project.find(job['args'].first)

      action = if project.forked?
                 "fork"
               else
                 "import"
               end

      project.import_state.mark_as_failed(_("Every %{action} attempt has failed: %{job_error_message}. Please try again.") % { action: action, job_error_message: job['error_message'] })
      Sidekiq.logger.warn "Failed #{job['class']} with #{job['args']}: #{job['error_message']}"
    end
  end
end
