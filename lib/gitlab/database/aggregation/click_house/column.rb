# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Column < PartDefinition
          attr_reader :name, :type, :expression, :secondary_expression

          def initialize(*args, **kwargs)
            super
            @secondary_expression = kwargs[:if]
          end

          def secondary_arel(_context)
            secondary_expression&.call
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
