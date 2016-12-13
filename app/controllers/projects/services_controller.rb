class Projects::ServicesController < Projects::ApplicationController
  include ServiceParams

  # Authorize
  before_action :authorize_admin_project!
  before_action :service, only: [:edit, :update, :test, :configure]

  respond_to :html

  layout "project_settings"

  def index
    @services = @project.find_or_initialize_services
  end

  def edit
  end

  def update
    if @service.update_attributes(service_params[:service])
      redirect_to(
        edit_namespace_project_service_path(@project.namespace, @project, @service.to_param),
        notice: 'Successfully updated.'
      )
    else
      render 'edit'
    end
  end

  def test
    return render_404 unless @service.can_test?

    data = @service.test_data(project, current_user)
    outcome = @service.test(data)

    if outcome[:success]
      message = { notice: 'We sent a request to the provided URL' }
    else
      error_message = "We tried to send a request to the provided URL but an error occurred"
      error_message << ": #{outcome[:result]}" if outcome[:result].present?
      message = { alert: error_message }
    end

    redirect_back_or_default(options: message)
  end

  def configure
    host = Gitlab.config.mattermost.host
    if @service.auto_config? && host
      @service.configure(host, current_user, params)

      redirect_to(
        edit_namespace_project_service_path(@project.namespace, @project, @service.to_param),
        notice: 'This service is now configured.'
      )
    else
      redirect_to(
        edit_namespace_project_service_path(@project.namespace, @project, @service.to_param),
        alert: 'This service can not be automatticly configured.'
      )
    end
  rescue Mattermost::NoSessionError
    redirect_to(
      edit_namespace_project_service_path(@project.namespace, @project, @service.to_param),
      alert: 'An error occurred, is Mattermost configured with Single Sign on?'
    )
  end

  private

  def service
    @service ||= @project.find_or_initialize_service(params[:id])
  end

  def configure_params
    params.require(:auto_configure).permit(:trigger, :team_id)
  end
end
