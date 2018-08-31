module EE
  module Gitlab
    module Prometheus
      module MetricGroup
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          def self.custom_metrics(project)
            project.prometheus_metrics.all.group_by(&:group_title).map do |name, metrics|
              MetricGroup.new(name: name, priority: 0, metrics: metrics.map(&:to_query_metric))
            end
          end

          override :for_project
          def self.for_project(project)
            super + custom_metrics(project)
          end
        end
      end
    end
  end
end
