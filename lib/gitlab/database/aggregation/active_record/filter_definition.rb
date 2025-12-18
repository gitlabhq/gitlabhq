# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        class FilterDefinition < PartDefinition
          attr_reader :max_size

          def initialize(*args, max_size: nil, **kwargs)
            super
            @max_size = max_size
          end

          def apply(_relation, _filter_config)
            raise NoMethodError
          end

          def validate_part(part)
            validate_max_size(part)
          end

          private

          def column(relation)
            expression&.call || relation.arel_table[name]
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
