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
      if @service.activated? && @service.category == :issue_tracker
        @project.update_attributes(issues_tracker: @service.to_param)
      end
      redirect_to edit_project_service_path(@project, @service.to_param),
       notice: 'Successfully updated.'
    else
      render 'edit'
    end
  end

  def test
    data = Gitlab::PushDataBuilder.build_sample(project, current_user)
    if @service.execute(data)
      message = { notice: 'We sent a request to the provided URL' }
    else
      message = { alert: 'We tried to send a request to the provided URL but error occured' }
    end

    redirect_to :back, message
  end

  private

  def service
    @service ||= @project.services.find { |service| service.to_param == params[:id] }
  end

  def service_params
    params.require(:service).permit(
      :title, :token, :type, :active, :api_key, :subdomain,
      :room, :recipients, :project_url, :webhook,
      :user_key, :device, :priority, :sound, :bamboo_url, :username, :password,
      :build_key, :server, :teamcity_url, :build_type,
      :description, :issues_url, :new_issue_url
    )
  end
end
