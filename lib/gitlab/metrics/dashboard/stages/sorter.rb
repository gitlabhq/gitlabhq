# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class Sorter < BaseStage
          def transform!
            missing_panel_groups! unless dashboard[:panel_groups].is_a? Array

            sort_groups!
            sort_panels!
          end

          private

          # Sorts the groups in the dashboard by the :priority key
          def sort_groups!
            dashboard[:panel_groups] = Gitlab::Utils.stable_sort_by(dashboard[:panel_groups]) { |group| -group[:priority].to_i }
          end

          # Sorts the panels in the dashboard by the :weight key
          def sort_panels!
            dashboard[:panel_groups].each do |group|
              missing_panels! unless group[:panels].is_a? Array

              group[:panels] = Gitlab::Utils.stable_sort_by(group[:panels]) { |panel| -panel[:weight].to_i }
            end
          end
        end
      end
    end
  end
end
