# frozen_string_literal: true

module Projects
  module Metrics
    module Dashboards
      class BuilderController < Projects::ApplicationController
        before_action :authorize_metrics_dashboard!

        feature_category :metrics
        urgency :low

        def panel_preview
          return not_found if Feature.enabled?(:remove_monitor_metrics)

          respond_to do |format|
            format.json do
              if rendered_panel.success?
                render json: rendered_panel.payload
              else
                render json: { message: rendered_panel.message }, status: :unprocessable_entity
              end
            end
          end
        end

        private

        def rendered_panel
          @panel_preview ||= ::Metrics::Dashboard::PanelPreviewService.new(project, panel_yaml, environment).execute
        end

        def panel_yaml
          params.require(:panel_yaml)
        end

        def environment
          @environment ||=
            if params[:environment]
              project.environments.find(params[:environment])
            else
              project.default_environment
            end
        end
      end
    end
  end
end
