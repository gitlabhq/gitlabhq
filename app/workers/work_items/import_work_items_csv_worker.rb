# frozen_string_literal: true

module WorkItems
  class ImportWorkItemsCsvWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    idempotent!
    feature_category :team_planning

    sidekiq_retries_exhausted do |job|
      Upload.find(job['args'][2]).destroy
    end

    def perform(current_user_id, project_id, upload_id)
      upload = Upload.find(upload_id)
      user = User.find(current_user_id)
      project = Project.find(project_id)

      WorkItems::ImportCsvService.new(user, project, upload.retrieve_uploader).execute
      upload.destroy!
    rescue ActiveRecord::RecordNotFound
      # Resources have been removed, job should not be retried
    end
  end
end
