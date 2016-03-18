class RepositoryImportWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  attr_accessor :project, :current_user

  def perform(project_id)
    @project = Project.find(project_id)
    @current_user = @project.creator

    result = Projects::ImportService.new(project, current_user).execute

    if result[:status] == :error
      project.update(import_error: result[:message])
      project.import_fail
      return
    end

    project.repository.after_import
    project.import_finish
  end
end
