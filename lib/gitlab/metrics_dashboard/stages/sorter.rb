# frozen_string_literal: true

module Gitlab
  module MetricsDashboard
    module Stages
      class Sorter < BaseStage
        def transform!(dashboard)
          sort_groups!(dashboard)
          sort_panels!(dashboard)
        end

        private

        # Sorts the groups in the dashboard by the :priority key
        def sort_groups!(dashboard)
          dashboard[:panel_groups] = dashboard[:panel_groups].sort_by { |group| -group[:priority].to_i }
        end

        # Sorts the panels in the dashboard by the :weight key
        def sort_panels!(dashboard)
          dashboard[:panel_groups].each do |group|
            group[:panels] = group[:panels].sort_by { |panel| -panel[:weight].to_i }
          end
        end
      end
    end
  end
end
