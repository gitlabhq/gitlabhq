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
    begin
      file_path = ArchiveRepositoryService.new(@project, params[:ref], params[:format]).execute
    rescue
      return head :not_found
    end

    if file_path
      # Send file to user
      response.headers["Content-Length"] = File.open(file_path).size.to_s
      send_file file_path
    else
      redirect_to request.fullpath
    end
  end
end
