# frozen_string_literal: true

class Projects::ServicesController < Projects::ApplicationController
  include Integrations::Params
  include InternalRedirect

  # Authorize
  before_action :authorize_admin_project!
  before_action :ensure_service_enabled
  before_action :integration
  before_action :web_hook_logs, only: [:edit, :update]
  before_action :set_deprecation_notice_for_prometheus_integration, only: [:edit, :update]
  before_action :redirect_deprecated_prometheus_integration, only: [:update]

  respond_to :html

  layout "project_settings"

  feature_category :integrations

  def edit
    @default_integration = Integration.default_integration(service.type, project)
  end

  def update
    @integration.attributes = integration_params[:integration]
    @integration.inherit_from_id = nil if integration_params[:integration][:inherit_from_id].blank?

    saved = @integration.save(context: :manual_change)

    respond_to do |format|
      format.html do
        if saved
          redirect_to redirect_path, notice: success_message
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
    if integration.testable?
      render json: service_test_response, status: :ok
    else
      render json: {}, status: :not_found
    end
  end

  private

  def redirect_path
    safe_redirect_path(params[:redirect_to]).presence || edit_project_service_path(@project, @integration)
  end

  def service_test_response
    unless @integration.update(integration_params[:integration])
      return { error: true, message: _('Validations failed.'), service_response: @integration.errors.full_messages.join(','), test_failed: false }
    end

    result = ::Integrations::Test::ProjectService.new(@integration, current_user, params[:event]).execute

    unless result[:success]
      return { error: true, message: s_('Integrations|Connection failed. Please check your settings.'), service_response: result[:message].to_s, test_failed: true }
    end

    result[:data].presence || {}
  rescue *Gitlab::HTTP::HTTP_ERRORS => e
    { error: true, message: s_('Integrations|Connection failed. Please check your settings.'), service_response: e.message, test_failed: true }
  end

  def success_message
    if integration.active?
      s_('Integrations|%{integration} settings saved and active.') % { integration: integration.title }
    else
      s_('Integrations|%{integration} settings saved, but not active.') % { integration: integration.title }
    end
  end

  def integration
    @integration ||= @project.find_or_initialize_integration(params[:id])
  end
  alias_method :service, :integration

  def web_hook_logs
    return unless integration.service_hook.present?

    @web_hook_logs ||= integration.service_hook.web_hook_logs.recent.page(params[:page])
  end

  def ensure_service_enabled
    render_404 unless service
  end

  def serialize_as_json
    integration
      .as_json(only: integration.json_fields)
      .merge(errors: integration.errors.as_json)
  end

  def redirect_deprecated_prometheus_integration
    redirect_to edit_project_service_path(project, integration) if integration.is_a?(::Integrations::Prometheus) && Feature.enabled?(:settings_operations_prometheus_service, project)
  end

  def set_deprecation_notice_for_prometheus_integration
    return if !integration.is_a?(::Integrations::Prometheus) || !Feature.enabled?(:settings_operations_prometheus_service, project)

    operations_link_start = "<a href=\"#{project_settings_operations_path(project)}\">"
    message = s_('PrometheusService|You can now manage your Prometheus settings on the %{operations_link_start}Operations%{operations_link_end} page. Fields on this page has been deprecated.') % { operations_link_start: operations_link_start, operations_link_end: "</a>" }
    flash.now[:alert] = message.html_safe
  end
end
