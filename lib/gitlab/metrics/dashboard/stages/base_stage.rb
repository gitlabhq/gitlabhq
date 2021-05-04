# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class BaseStage
          include Gitlab::Metrics::Dashboard::Defaults

          attr_reader :project, :dashboard, :params

          def initialize(project, dashboard, params)
            @project = project
            @dashboard = dashboard
            @params = params
          end

          # Entry-point to the stage
          def transform!
            raise NotImplementedError
          end

          protected

          def missing_panel_groups!
            raise Errors::LayoutError, 'Top-level key :panel_groups must be an array'
          end

          def missing_panels!
            raise Errors::LayoutError, 'Each "panel_group" must define an array :panels'
          end

          def missing_metrics!
            raise Errors::LayoutError, 'Each "panel" must define an array :metrics'
          end

          def for_metrics
            missing_panel_groups! unless dashboard[:panel_groups].is_a?(Array)

            for_panel_groups do |panel_group|
              for_panels_in(panel_group) do |panel|
                missing_metrics! unless panel[:metrics].is_a?(Array)

                panel[:metrics].each do |metric|
                  yield metric
                end
              end
            end
          end

          def for_variables
            return unless dashboard.dig(:templating, :variables).is_a?(Hash)

            dashboard.dig(:templating, :variables).each do |variable_name, variable|
              yield variable_name, variable
            end
          end

          def for_panel_groups
            dashboard[:panel_groups].each do |panel_group|
              yield panel_group
            end
          end

          def for_panels_in(panel_group)
            missing_panels! unless panel_group[:panels].is_a?(Array)

            panel_group[:panels].each do |panel|
              yield panel
            end
          end
        end
      end
    end
  end
end
