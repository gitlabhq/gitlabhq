class Projects::ServicesController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_admin_project!
  before_filter :service, only: [:edit, :update, :test]

  respond_to :html

  layout "project_settings"

  def index
    @project.build_missing_services
    @services = @project.services.visible.reload
  end

  def edit
  end

  def update
    if @service.update_attributes(service_params)
      redirect_to(
        edit_namespace_project_service_path(@project.namespace, @project,
                                            @service.to_param, notice:
                                            'Successfully updated.')
      )
    else
      render 'edit'
    end
  end

  def test
    data = Gitlab::PushDataBuilder.build_sample(project, current_user)
    if @service.execute(data)
      message = { notice: 'We sent a request to the provided URL' }
    else
      message = { alert: 'We tried to send a request to the provided URL but an error occured' }
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
      :description, :issues_url, :new_issue_url, :restrict_to_branch
    )
  end
end
