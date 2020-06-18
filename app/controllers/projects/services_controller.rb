# frozen_string_literal: true

class Projects::ServicesController < Projects::ApplicationController
  include ServiceParams
  include InternalRedirect

  # Authorize
  before_action :authorize_admin_project!
  before_action :ensure_service_enabled
  before_action :service
  before_action :web_hook_logs, only: [:edit, :update]
  before_action :set_deprecation_notice_for_prometheus_service, only: [:edit, :update]
  before_action :redirect_deprecated_prometheus_service, only: [:update]
  before_action only: :edit do
    push_frontend_feature_flag(:integration_form_refactor)
  end

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
          target_url = safe_redirect_path(params[:redirect_to]).presence || project_settings_integrations_path(@project)
          redirect_to target_url, notice: success_message
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
    unless @service.update(service_params[:service])
      return { error: true, message: _('Validations failed.'), service_response: @service.errors.full_messages.join(','), test_failed: false }
    end

    result = Integrations::Test::ProjectService.new(@service, current_user, params[:event]).execute

    unless result[:success]
      return { error: true, message: _('Test failed.'), service_response: result[:message].to_s, test_failed: true }
    end

    {}
  rescue Gitlab::HTTP::BlockedUrlError => e
    { error: true, message: _('Test failed.'), service_response: e.message, test_failed: true }
  end

  def success_message
    message = @service.active? ? _('activated') : _('settings saved, but not activated')

    _('%{service_title} %{message}.') % { service_title: @service.title, message: message }
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

  def redirect_deprecated_prometheus_service
    redirect_to edit_project_service_path(project, @service) if @service.is_a?(::PrometheusService) && Feature.enabled?(:settings_operations_prometheus_service, project)
  end

  def set_deprecation_notice_for_prometheus_service
    return if !@service.is_a?(::PrometheusService) || !Feature.enabled?(:settings_operations_prometheus_service, project)

    operations_link_start = "<a href=\"#{project_settings_operations_path(project)}\">"
    message = s_('PrometheusService|You can now manage your Prometheus settings on the %{operations_link_start}Operations%{operations_link_end} page. Fields on this page has been deprecated.') % { operations_link_start: operations_link_start, operations_link_end: "</a>" }
    flash.now[:alert] = message.html_safe
  end
end
