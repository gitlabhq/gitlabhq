# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class PanelIdsInserter < BaseStage
          # For each panel within given dashboard inserts panel_id unique in scope of the dashboard
          def transform!
            missing_panel_groups! unless dashboard[:panel_groups]

            for_panels_group_with_panels do |panel_group, panel|
              id = generate_panel_id(panel_group, panel)
              remove_panel_ids! && break if duplicated_panel_id?(id)

              insert_panel_id(id, panel)
            end
          rescue ActiveModel::UnknownAttributeError => error
            remove_panel_ids!
            Gitlab::ErrorTracking.log_exception(error)
          end

          private

          def generate_panel_id(group, panel)
            ::PerformanceMonitoring::PrometheusPanel.new(panel.with_indifferent_access).id(group[:group])
          end

          def insert_panel_id(id, panel)
            track_inserted_panel_ids(id, panel)
            panel[:id] = id
          end

          def track_inserted_panel_ids(id, panel)
            panel_ids[id] = panel
          end

          def duplicated_panel_id?(id)
            panel_ids.key?(id)
          end

          def remove_panel_ids!
            panel_ids.each_value { |panel| panel.delete(:id) }
          end

          def panel_ids
            @_panel_ids ||= {}
          end

          def for_panels_group_with_panels
            for_panel_groups do |panel_group|
              for_panels_in(panel_group) do |panel|
                yield panel_group, panel
              end
            end
          end
        end
      end
    end
  end
end
