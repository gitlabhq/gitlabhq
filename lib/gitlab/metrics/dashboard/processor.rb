# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      # Responsible for processesing a dashboard hash, inserting
      # relevant DB records & sorting for proper rendering in
      # the UI. These includes shared metric info, custom metrics
      # info, and alerts (only in EE).
      class Processor
        SYSTEM_SEQUENCE = [
          Stages::CommonMetricsInserter,
          Stages::ProjectMetricsInserter,
          Stages::EndpointInserter,
          Stages::Sorter
        ].freeze

        PROJECT_SEQUENCE = [
          Stages::CommonMetricsInserter,
          Stages::EndpointInserter,
          Stages::Sorter
        ].freeze

        def initialize(project, environment, dashboard)
          @project = project
          @environment = environment
          @dashboard = dashboard
        end

        # Returns a new dashboard hash with the results of
        # running transforms on the dashboard.
        def process(insert_project_metrics:)
          @dashboard.deep_symbolize_keys.tap do |dashboard|
            sequence(insert_project_metrics).each do |stage|
              stage.new(@project, @environment, dashboard).transform!
            end
          end
        end

        private

        def sequence(insert_project_metrics)
          insert_project_metrics ? SYSTEM_SEQUENCE : PROJECT_SEQUENCE
        end
      end
    end
  end
end
