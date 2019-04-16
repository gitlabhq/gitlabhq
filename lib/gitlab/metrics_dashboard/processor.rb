# frozen_string_literal: true

module Gitlab
  module MetricsDashboard
    class Processor
      STAGES = [CommonMetricsInserter, Sorter, ProjectMetricsInserter]

      def initialize(dashboard, project)
        @dashboard = dashboard.deep_transform_keys(&:to_sym)
        @project = project
      end

      def process
        STAGES.each { |stage| stage.transform!(@dashboard, @project) }

        @dashboard.to_json
      end
    end
  end
end
