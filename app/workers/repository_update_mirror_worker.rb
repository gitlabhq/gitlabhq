class RepositoryUpdateMirrorWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  attr_accessor :project, :repository, :current_user

  def perform(project_id)
    @project = Project.find(project_id)
    @current_user = @project.mirror_user || @project.creator

    result = Projects::UpdateMirrorService.new(@project, @current_user).execute
    if result[:status] == :error
      project.mark_import_as_failed(result[:message])
      return
    end

    project.import_finish
  end
end
