# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        class Mean < Column
          def initialize(name, type = :float, expression: nil, formatter: nil, description: nil)
            super
          end

          def identifier
            :"mean_#{name}"
          end

          def to_arel(context)
            arel_node = expression ? expression.call : context[:arel_table][name]
            arel_node.average
          end
        end
      end
    end
  end
end
