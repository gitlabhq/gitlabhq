class RepositoryImportWorker
  ImportError = Class.new(StandardError)

  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  sidekiq_options status_expiration: StuckImportJobsWorker::IMPORT_EXPIRATION

  attr_accessor :project, :current_user

  def perform(project_id)
    @project = Project.find(project_id)
    @current_user = @project.creator

    project.import_start

    Gitlab::Metrics.add_event(:import_repository,
                              import_url: @project.import_url,
                              path: @project.full_path)

    project.update_columns(import_jid: self.jid, import_error: nil)

    result = Projects::ImportService.new(project, current_user).execute
    raise ImportError, result[:message] if result[:status] == :error

    project.repository.after_import
    project.import_finish
  rescue ImportError => ex
    fail_import(project, ex.message)
    raise
  rescue => ex
    return unless project

    fail_import(project, ex.message)
    raise ImportError, "#{ex.class} #{ex.message}"
  end

  private

  def fail_import(project, message)
    project.mark_import_as_failed(message)
  end
end
