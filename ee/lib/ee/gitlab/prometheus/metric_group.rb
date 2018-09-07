module EE
  module Gitlab
    module Prometheus
      module MetricGroup
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          def custom_metrics(project)
            project.prometheus_metrics.all.group_by(&:group_title).map do |name, metrics|
              ::Gitlab::Prometheus::MetricGroup.new(
                name: name, priority: 0, metrics: metrics.map(&:to_query_metric))
            end
          end

          override :for_project
          def for_project(project)
            super + custom_metrics(project)
          end
        end
      end
    end
  end
end
