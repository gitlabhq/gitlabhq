# frozen_string_literal: true

module Gitlab
  module MetricsDashboard
    class Processor
      def initialize(dashboard, project, environment)
        @dashboard = dashboard.deep_transform_keys(&:to_sym)
        @project = project
        @environment = environment
      end

      def stages
        @stages ||= [
          Stages::CommonMetricsInserter,
          Stages::ProjectMetricsInserter,
          Stages::Sorter
        ].freeze
      end

      def process
        stages.each { |stage| stage.new(@dashboard, @project, @environment).transform! }

        @dashboard
      end
    end
  end
end
