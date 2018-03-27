class Projects::PagesController < Projects::ApplicationController
  layout 'project_settings'

  before_action :require_pages_enabled!
  before_action :authorize_read_pages!, only: [:show]
  before_action :authorize_update_pages!, except: [:show]

  def show
    @domains = @project.pages_domains.order(:domain)
  end

  def destroy
    project.remove_pages
    project.pages_domains.destroy_all

    respond_to do |format|
      format.html  do
        redirect_to project_pages_path(@project),
                    status: 302,
                    notice: 'Pages were removed'
      end
    end
  end

  def update
    result = Projects::UpdateService.new(@project, current_user, project_params).execute

    respond_to do |format|
      format.html do
        if result[:status] == :success
          flash[:notice] = 'Your changes have been saved'
        else
          flash[:alert] = 'Something went wrong on our end'
        end

        redirect_to project_pages_path(@project)
      end
    end
  end

  private

  def project_params
    params.require(:project).permit(:pages_https_only)
  end
end
