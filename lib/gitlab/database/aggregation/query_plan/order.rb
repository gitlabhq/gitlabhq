# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class QueryPlan
        class Order < BasePart
          attr_reader :plan_part

          def initialize(plan_part, configuration)
            @plan_part = plan_part
            @configuration = configuration
          end

          def definition
            plan_part&.definition
          end

          def instance_key
            plan_part&.instance_key
          end

          def direction
            configuration[:direction]
          end
        end
      end
    end
  end
end
