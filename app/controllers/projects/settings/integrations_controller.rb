# frozen_string_literal: true

module Projects
  module Settings
    class IntegrationsController < Projects::ApplicationController
      include ::Integrations::Params
      include ::InternalRedirect

      before_action :authorize_admin_integrations!
      before_action :ensure_integration_enabled, only: [:edit, :update, :test]
      before_action :integration, only: [:edit, :update, :test]
      before_action :default_integration, only: [:edit, :update]
      before_action :web_hook_logs, only: [:edit, :update]
      before_action -> { check_test_rate_limit! }, only: :test

      before_action :render_404, only: [:edit, :update, :test], if: -> do
        integration.is_a?(::Integrations::Prometheus) && Feature.enabled?(:remove_monitor_metrics)
      end

      respond_to :html

      layout "project_settings"

      feature_category :integrations
      urgency :low, [:test]

      def index
        @integrations = @project.find_or_initialize_integrations
      end

      def edit; end

      def update
        attributes = integration_params[:integration]

        if use_inherited_settings?(attributes)
          integration.inherit_from_id = default_integration.id

          if updated = integration.save(context: :manual_change)
            ::Integrations::Propagation::BulkUpdateService.new(default_integration, [integration]).execute
          end
        else
          attributes[:inherit_from_id] = nil
          integration.attributes = attributes
          updated = integration.save(context: :manual_change)
        end

        respond_to do |format|
          format.html do
            if updated
              redirect_to redirect_path, notice: success_message
            else
              render 'edit'
            end
          end

          format.json do
            status = updated ? :ok : :unprocessable_entity

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

      private

      def redirect_path
        safe_redirect_path(params[:redirect_to]).presence ||
          edit_project_settings_integration_path(project, integration)
      end

      def integration_test_response
        integration.assign_attributes(integration_params[:integration])

        unless integration.valid?
          return {
            error: true,
            message: _('Validations failed.'),
            service_response: integration.errors.full_messages.join(', '),
            test_failed: false
          }
        end

        result = ::Integrations::Test::ProjectService.new(integration, current_user, params[:event]).execute

        unless result[:success]
          return {
            error: true,
            message: s_('Integrations|Connection failed. Check your integration settings.'),
            service_response: result[:result].to_s,
            test_failed: true
          }
        end

        result[:data].presence || {}
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        {
          error: true,
          message: s_('Integrations|Connection failed. Check your integration settings.'),
          service_response: e.message,
          test_failed: true
        }
      end

      def success_message
        if integration.active?
          format(s_('Integrations|%{integration} settings saved and active.'), integration: integration.title)
        else
          format(s_('Integrations|%{integration} settings saved, but not active.'), integration: integration.title)
        end
      end

      def integration
        @integration ||= project.find_or_initialize_integration(params[:id])
      end

      def default_integration
        @default_integration ||= Integration.default_integration(integration.type, project)
      end

      def web_hook_logs
        return unless integration.try(:service_hook).present?

        @web_hook_logs ||= integration.service_hook.web_hook_logs.recent.page(params[:page]).without_count
      end

      def ensure_integration_enabled
        render_404 unless integration
      end

      def serialize_as_json
        integration
          .as_json(only: integration.json_fields)
          .merge(errors: integration.errors.as_json)
      end

      def use_inherited_settings?(attributes)
        default_integration && attributes[:inherit_from_id] == default_integration.id.to_s
      end

      def check_test_rate_limit!
        check_rate_limit!(:project_testing_integration, scope: [@project, current_user]) do
          render json: {
            error: true,
            message: _('This endpoint has been requested too many times. Try again later.')
          }, status: :ok
        end
      end
    end
  end
end
