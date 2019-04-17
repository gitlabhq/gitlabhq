# frozen_string_literal: true

module Gitlab
  module MetricsDashboard
    module Stages
      class BaseStage
        DEFAULT_PANEL_TYPE = 'area-chart'

        attr_reader :dashboard, :project, :environment

        def initialize(dashboard, project, environment)
          @dashboard = dashboard
          @project = project
          @environment = environment
        end

        # Entry-point to the stage
        # @param dashboard [Hash]
        # @param project [Project]
        # @param environment [Environment]
        def transform!
          raise NotImplementedError
        end

        protected

        def for_metrics
          dashboard[:panel_groups].each do |panel_group|
            panel_group[:panels].each do |panel|
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
