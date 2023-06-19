# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountDeploymentsMetric < DatabaseMetric
          operation :count

          start { Deployment.minimum(:id) }
          finish { Deployment.maximum(:id) }

          def initialize(metric_definition)
            super

            raise ArgumentError, 'Missing Deployment type' unless type
            raise ArgumentError, "Invalid Deployment type: #{type}" unless type.in?(%i[all success failed])
          end

          private

          def type
            options[:type].to_sym
          end

          def relation
            @metric_relation = case type
                               when :all
                                 Deployment
                               when :success
                                 Deployment.success
                               when :failed
                                 Deployment.failed
                               end.where(time_constraints)
          end
        end
      end
    end
  end
end
