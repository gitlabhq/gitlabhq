# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class CustomMetricsDetailsInserter < BaseStage
          def transform!
            dashboard[:panel_groups].each do |panel_group|
              next unless panel_group

              has_custom_metrics = custom_group_titles.include?(panel_group[:group])
              panel_group[:has_custom_metrics] = has_custom_metrics

              panel_group[:panels].each do |panel|
                next unless panel

                panel[:metrics].each do |metric|
                  next unless metric

                  metric[:edit_path] = has_custom_metrics ? edit_path(metric) : nil
                end
              end
            end
          end

          private

          def custom_group_titles
            @custom_group_titles ||= Enums::PrometheusMetric.custom_group_details.values.map { |group_details| group_details[:group_title] }
          end

          def edit_path(metric)
            Gitlab::Routing.url_helpers.edit_project_prometheus_metric_path(project, metric[:metric_id])
          end
        end
      end
    end
  end
end
