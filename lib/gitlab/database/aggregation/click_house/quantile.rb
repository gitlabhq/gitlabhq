# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Quantile < Column
          include ParameterizedDefinition

          self.supported_parameters = %i[quantile]

          DEFAULT_QUANTILE = 0.5

          def initialize(name, type = :float, expression = nil, **kwargs)
            super
          end

          def identifier
            :"#{name}_quantile"
          end

          def to_outer_arel(context)
            quantile = instance_parameter(:quantile, context[name]) || DEFAULT_QUANTILE

            inner_column = Arel::Table.new(context[:inner_query_name])[context.fetch(:local_alias, name)]

            Arel.sql("quantile(?)(?)", context[:scope].quote(quantile), inner_column)
          end
        end
      end
    end
  end
end
