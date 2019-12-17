# frozen_string_literal: true

class Projects::ServicesController < Projects::ApplicationController
  include ServiceParams

  # Authorize
  before_action :authorize_admin_project!
  before_action :ensure_service_enabled
  before_action :service
  before_action :web_hook_logs, only: [:edit, :update]

  respond_to :html

  layout "project_settings"

  def edit
  end

  def update
    @service.attributes = service_params[:service]

    saved = @service.save(context: :manual_change)

    respond_to do |format|
      format.html do
        if saved
          redirect_to project_settings_integrations_path(@project),
            notice: success_message
        else
          render 'edit'
        end
      end

      format.json do
        status = saved ? :ok : :unprocessable_entity

        render json: serialize_as_json, status: status
      end
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
    if @service.update(service_params[:service])
      data = @service.test_data(project, current_user)
      outcome = @service.test(data)

      if outcome[:success]
        {}
      else
        { error: true, message: _('Test failed.'), service_response: outcome[:result].to_s, test_failed: true }
      end
    else
      { error: true, message: _('Validations failed.'), service_response: @service.errors.full_messages.join(','), test_failed: false }
    end
  rescue Gitlab::HTTP::BlockedUrlError => e
    { error: true, message: _('Test failed.'), service_response: e.message, test_failed: true }
  end

  def success_message
    if @service.active?
      _("%{service_title} activated.") % { service_title: @service.title }
    else
      _("%{service_title} settings saved, but not activated.") % { service_title: @service.title }
    end
  end

  def service
    @service ||= @project.find_or_initialize_service(params[:id])
  end

  def web_hook_logs
    return unless @service.service_hook.present?

    @web_hook_logs ||= @service.service_hook.web_hook_logs.recent.page(params[:page])
  end

  def ensure_service_enabled
    render_404 unless service
  end

  def serialize_as_json
    @service
      .as_json(only: @service.json_fields)
      .merge(errors: @service.errors.as_json)
  end
end
