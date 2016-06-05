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
      project.mark_import_as_failed(result[:message])
      return
    end

    project.repository.after_import
    project.import_finish

    # Explicitly update mirror so that upstream remote is created and fetched
    project.update_mirror
  end
end
