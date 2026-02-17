# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class MetricDefinition < PartDefinition
          def initialize(*args, **kwargs)
            super
            @secondary_expression = kwargs[:if]
          end

          def to_inner_arel(context)
            expression ? expression.call : context[:scope][name]
          end

          def to_outer_arel(context)
            Arel::Table.new(context[:inner_query_name])[context.fetch(:local_alias, name)]
          end
        end
      end
    end
  end
end
