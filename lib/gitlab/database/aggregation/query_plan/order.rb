# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class QueryPlan
        class Order < BasePart
          attr_reader :plan_part

          delegate :definition, :instance_key, to: :plan_part

          def initialize(plan_part, configuration)
            @plan_part = plan_part
            @configuration = configuration
          end

          def direction
            configuration[:direction]
          end
        end
      end
    end
  end
end
