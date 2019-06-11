# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class BaseStage
          DashboardProcessingError = Class.new(StandardError)
          LayoutError = Class.new(DashboardProcessingError)

          DEFAULT_PANEL_TYPE = 'area-chart'

          attr_reader :project, :environment, :dashboard

          def initialize(project, environment, dashboard)
            @project = project
            @environment = environment
            @dashboard = dashboard
          end

          # Entry-point to the stage
          def transform!
            raise NotImplementedError
          end

          protected

          def missing_panel_groups!
            raise LayoutError.new('Top-level key :panel_groups must be an array')
          end

          def missing_panels!
            raise LayoutError.new('Each "panel_group" must define an array :panels')
          end

          def missing_metrics!
            raise LayoutError.new('Each "panel" must define an array :metrics')
          end

          def for_metrics
            missing_panel_groups! unless dashboard[:panel_groups].is_a?(Array)

            dashboard[:panel_groups].each do |panel_group|
              missing_panels! unless panel_group[:panels].is_a?(Array)

              panel_group[:panels].each do |panel|
                missing_metrics! unless panel[:metrics].is_a?(Array)

                panel[:metrics].each do |metric|
                  yield metric
                end
              end
            end
          end
        end
      end
    end
  end
end
