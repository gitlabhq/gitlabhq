# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        class DateBucketDimension < DimensionDefinition
          include ParameterizedDefinition

          GRANULARITIES_MAP = {
            daily: :day,
            weekly: :week,
            monthly: :month,
            yearly: :year
          }.with_indifferent_access.freeze

          DEFAULT_GRANULARITY = :monthly

          def to_arel(context)
            granularity = instance_parameter(:granularity, context[name]) || DEFAULT_GRANULARITY

            quoted_string = context[:scope].model.connection.quote(GRANULARITIES_MAP[granularity])

            expr = expression ? expression.call : context[:scope].arel_table[name]
            Arel::Nodes::NamedFunction.new('date_trunc', [Arel.sql(quoted_string), expr])
          end
        end
      end
    end
  end
end
