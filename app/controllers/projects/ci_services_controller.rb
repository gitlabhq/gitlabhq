class Projects::CiServicesController < Projects::ApplicationController
  before_action :ci_project
  before_action :authorize_admin_project!

  layout "project_settings"

  def index
    @ci_project.build_missing_services
    @services = @ci_project.services.reload
  end

  def edit
    service
  end

  def update
    if @service.update_attributes(service_params)
      redirect_to edit_namespace_project_ci_service_path(@project, @project.namespace, @service.to_param)
    else
      render 'edit'
    end
  end

  def test
    last_build = @project.builds.last

    if @service.execute(last_build)
      message = { notice: 'We successfully tested the service' }
    else
      message = { alert: 'We tried to test the service but error occurred' }
    end

    redirect_back_or_default(options: message)
  end

  private

  def service
    @service ||= @ci_project.services.find { |service| service.to_param == params[:id] }
  end

  def service_params
    params.require(:service).permit(
      :type, :active, :webhook, :notify_only_broken_builds,
      :email_recipients, :email_only_broken_builds, :email_add_pusher,
      :hipchat_token, :hipchat_room, :hipchat_server
    )
  end
end
