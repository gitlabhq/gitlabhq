class Projects::RepositoriesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project, except: :create
  before_action :authorize_download_code!
  before_action :authorize_admin_project!, only: :create

  def create
    @project.create_repository

    redirect_to project_path(@project)
  end

  def archive
    RepositoryArchiveCacheWorker.perform_async
    headers.store(*Gitlab::Workhorse.send_git_archive(@project, params[:ref], params[:format]))
    head :ok
  rescue => ex
    logger.error("#{self.class.name}: #{ex}")
    return git_not_found!
  end
end
