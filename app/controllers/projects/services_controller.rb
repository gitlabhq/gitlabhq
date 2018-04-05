class Projects::ServicesController < Projects::ApplicationController
  include ServiceParams

  # Authorize
  before_action :authorize_admin_project!
  before_action :ensure_service_enabled
  before_action :service

  respond_to :html

  layout "project_settings"

  def edit
  end

  def update
    @service.attributes = service_params[:service]

    if @service.save(context: :manual_change)
      redirect_to(project_settings_integrations_path(@project), notice: success_message)
    else
      render 'edit'
    end
  end

  def test
    if @service.can_test?
      render json: service_test_response, status: :ok
    else
      render json: {}, status: :not_found
    end
  end

  private

  def service_test_response
    if @service.update_attributes(service_params[:service])
      data = @service.test_data(project, current_user)
      outcome = @service.test(data)

      if outcome[:success]
        {}
      else
        { error: true, message: 'Test failed.', service_response: outcome[:result].to_s }
      end
    else
      { error: true, message: 'Validations failed.', service_response: @service.errors.full_messages.join(',') }
    end
  rescue Gitlab::HTTP::BlockedUrlError => e
    { error: true, message: 'Test failed.', service_response: e.message }
  end

  def success_message
    if @service.active?
      "#{@service.title} activated."
    else
      "#{@service.title} settings saved, but not activated."
    end
  end

  def service
    @service ||= @project.find_or_initialize_service(params[:id])
  end

  def ensure_service_enabled
    render_404 unless service
  end
end
