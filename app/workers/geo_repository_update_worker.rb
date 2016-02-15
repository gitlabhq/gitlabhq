class GeoRepositoryUpdateWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  attr_accessor :project, :repository, :current_user

  def perform(project_id)
    @project = Project.find(project_id)

    fetch_repository(@project.repository, @project.url_to_repo)
    # @current_user = @project.mirror_user || @project.creator
    # Projects::UpdateMirrorService.new(@project, @current_user).execute
  end

  private

  def fetch_repository(repository, remote_url)
    repository.fetch_upstream(remote_url)
  end
end
