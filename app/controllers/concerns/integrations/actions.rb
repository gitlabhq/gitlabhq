# frozen_string_literal: true

module Integrations::Actions
  extend ActiveSupport::Concern

  included do
    include Integrations::Params
    include IntegrationsHelper

    # :overrides is defined in Admin:IntegrationsController
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :ensure_integration_enabled, only: [:edit, :update, :overrides, :test]
    before_action :integration, only: [:edit, :update, :overrides, :test]
    # rubocop:enable Rails/LexicallyScopedActionFilter

    before_action :render_404, only: [:edit, :update, :overrides, :test], if: -> do
      integration.is_a?(::Integrations::Prometheus) && Feature.enabled?(:remove_monitor_metrics)
    end

    urgency :low, [:test]
  end

  def edit
    render 'shared/integrations/edit'
  end

  def update
    saved = integration.update(integration_params[:integration])

    respond_to do |format|
      format.html do
        if saved
          PropagateIntegrationWorker.perform_async(integration.id)
          redirect_to scoped_edit_integration_path(integration, project: integration.project, group: integration.group),
            notice: success_message
        else
          render 'shared/integrations/edit'
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
      render json: integration_test_response, status: :ok
    else
      render json: {}, status: :not_found
    end
  end

  def reset
    if integration.manual_activation?
      integration.destroy!

      flash[:notice] = s_('Integrations|This integration, and inheriting projects were reset.')

      render json: {}, status: :ok
    else
      render json: { message: s_('Integrations|Integration cannot be reset.') }, status: :unprocessable_entity
    end
  end

  private

  def integration
    @integration ||= find_or_initialize_non_project_specific_integration(params[:id])
  end

  def ensure_integration_enabled
    render_404 unless integration
  end

  def success_message
    if integration.active?
      format(s_('Integrations|%{integration} settings saved and active.'), integration: integration.title)
    else
      format(s_('Integrations|%{integration} settings saved, but not active.'), integration: integration.title)
    end
  end

  def serialize_as_json
    integration
      .as_json(only: integration.json_fields)
      .merge(errors: integration.errors.as_json)
  end

  def integration_test_response
    integration.assign_attributes(integration_params[:integration])

    result = if integration.project_level?
               ::Integrations::Test::ProjectService.new(integration, current_user, params[:event]).execute
             elsif integration.group_level?
               ::Integrations::Test::GroupService.new(integration, current_user, params[:event]).execute
             else
               {}
             end

    unless result[:success]
      return {
        error: true,
        message: s_('Integrations|Connection failed. Check your integration settings.'),
        service_response: result[:result].to_s,
        test_failed: true
      }
    end

    result[:data].presence || {}
  end
end
