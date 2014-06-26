class Projects::ServicesController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_admin_project!
  before_filter :service, only: [:edit, :update, :test]

  respond_to :html

  layout "project_settings"

  def index
    @project.build_missing_services
    @services = @project.services.reload
  end

  def edit
  end

  def update
    if @service.update_attributes(service_params)
      redirect_to edit_project_service_path(@project, @service.to_param)
    else
      render 'edit'
    end
  end

  def test
    data = GitPushService.new.sample_data(project, current_user)

    @service.execute(data)

    redirect_to :back
  end

  private

  def service
    @service ||= @project.services.find { |service| service.to_param == params[:id] }
  end

  def service_params
    params.require(:service).permit(
      :title, :token, :type, :active, :api_key, :subdomain,
      :room, :recipients, :project_url
    )
  end
end
