# frozen_string_literal: true

module Gitlab
  module MetricsDashboard
    module Stages
      class BaseStage
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

        def for_metrics(dashboard)
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
