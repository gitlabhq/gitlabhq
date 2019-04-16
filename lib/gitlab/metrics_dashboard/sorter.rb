# frozen_string_literal: true

module Gitlab
  module MetricsDashboard
    class Sorter
      class << self
        def transform!(dashboard, _project)
          sort_groups!(dashboard)
          sort_panels!(dashboard)
        end

        private

        # Sorts the groups in the dashboard by the :priority key
        def sort_groups!(dashboard)
          dashboard[:panel_groups] = dashboard[:panel_groups].sort_by { |group| group[:priority] }.reverse
        end

        # Sorts the panels in the dashboard by the :weight key
        def sort_panels!(dashboard)
          dashboard[:panel_groups].each do |group|
            group[:panels] = group[:panels].sort_by { |panel| panel[:weight] }.reverse
          end
        end
      end
    end
  end
end
