# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class FilterDefinition < PartDefinition
          attr_reader :max_size

          def initialize(name, type, expression = nil, **kwargs)
            super
            @merge_column = kwargs[:merge_column]
            @max_size = kwargs[:max_size]
          end

          def apply_inner(query_builder, filter_config)
            apply(query_builder, filter_config)
          end

          def validate_part(part)
            validate_max_size(part)
          end

          private

          def merge_column?
            !!@merge_column
          end

          def column(query_builder)
            expression&.call || query_builder.table[name]
          end

          def apply(_query_builder, _filter_config)
            raise NoMethodError
          end

          def validate_max_size(part)
            return unless max_size && part.configuration[:values].size > max_size

            part.errors.add(:values,
              format(s_("AggregationEngine|maximum size of %{max_size} exceeded for filter `%{key}`"),
                max_size: max_size,
                key: part.instance_key))
          end
        end
      end
    end
  end
end
