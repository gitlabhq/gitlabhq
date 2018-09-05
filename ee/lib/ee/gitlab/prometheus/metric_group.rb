module EE
  module Gitlab
    module Prometheus
      module MetricGroup
        module ClassMethods
          def custom_metrics(project)
            project.prometheus_metrics.all.group_by(&:group_title).map do |name, metrics|
              ::Gitlab::Prometheus::MetricGroup.new(
                name: name, priority: 0, metrics: metrics.map(&:to_query_metric))
            end
          end

          def for_project(project)
            super + custom_metrics(project)
          end
        end

        def self.prepended(base)
          base.singleton_class.prepend ClassMethods
        end
      end
    end
  end
end
