# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class TrackPanelType < BaseStage
          def transform!
            for_panel_groups do |panel_group|
              for_panels_in(panel_group) do |panel|
                track_panel_type(panel)
              end
            end
          end

          private

          def track_panel_type(panel)
            panel_type = panel[:type]

            Gitlab::Tracking.event('MetricsDashboard::Chart', 'chart_rendered', label: panel_type)
          end
        end
      end
    end
  end
end
