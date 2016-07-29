class Projects::PagesController < Projects::ApplicationController
  layout 'project_settings'

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
        redirect_to(namespace_project_pages_path(@project.namespace, @project),
                    notice: 'Pages were removed')
      end
    end
  end
end
