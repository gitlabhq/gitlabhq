# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      # Responsible for processesing a dashboard hash, inserting
      # relevant DB records & sorting for proper rendering in
      # the UI. These includes shared metric info, custom metrics
      # info, and alerts (only in EE).
      class Processor
        def initialize(project, dashboard, sequence, params)
          @project = project
          @dashboard = dashboard
          @sequence = sequence
          @params = params
        end

        # Returns a new dashboard hash with the results of
        # running transforms on the dashboard.
        # @return [Hash, nil]
        def process
          return unless @dashboard

          @dashboard.deep_symbolize_keys.tap do |dashboard|
            @sequence.each do |stage|
              stage.new(@project, dashboard, @params).transform!
            end
          end
        end
      end
    end
  end
end
