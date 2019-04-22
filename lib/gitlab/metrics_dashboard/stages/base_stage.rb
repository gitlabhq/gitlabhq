# frozen_string_literal: true

module Gitlab
  module MetricsDashboard
    module Stages
      class BaseStage
        DashboardLayoutError = Class.new(StandardError)

        DEFAULT_PANEL_TYPE = 'area-chart'

        attr_reader :project, :environment

        def initialize(project, environment)
          @project = project
          @environment = environment
        end

        # Entry-point to the stage
        # @param dashboard [Hash]
        # @param project [Project]
        # @param environment [Environment]
        def transform!(_dashboard)
          raise NotImplementedError
        end

        protected

        def missing_panel_groups!
          raise DashboardLayoutError.new('Top-level key :panel_groups must be an array')
        end

        def missing_panels!
          raise DashboardLayoutError.new('Each "panel_group" must define an array :panels')
        end

        def missing_metrics!
          raise DashboardLayoutError.new('Each "panel" must define an array :metrics')
        end

        def for_metrics(dashboard)
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
