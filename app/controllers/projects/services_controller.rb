class Projects::ServicesController < Projects::ApplicationController
  include ServiceParams

  # Authorize
  before_action :authorize_admin_project!
  before_action :service, only: [:edit, :update, :test]
  before_action :update_service, only: [:update, :test]

  respond_to :html

  layout "project_settings"

  def edit
  end

  def update
    if @service.save(context: :manual_change)
      redirect_to(project_settings_integrations_path(@project), notice: success_message)
    else
      render 'edit'
    end
  end

  def test
    message = {}

    if @service.can_test?
      data = @service.test_data(project, current_user)
      outcome = @service.test(data)

      unless outcome[:success]
        message = { error: true, message: 'Test failed.', service_response: outcome[:result].to_s }
      end

      status = :ok
    else
      status = :not_found
    end

    render json: message, status: status
  end

  private

  def success_message
    if @service.active?
      "#{@service.title} activated."
    else
      "#{@service.title} settings saved, but not activated."
    end
  end

  def update_service
    @service.assign_attributes(service_params[:service])
  end

  def service
    @service ||= @project.find_or_initialize_service(params[:id])
  end
end
