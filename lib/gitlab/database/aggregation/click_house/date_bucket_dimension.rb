# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class DateBucketDimension < DimensionDefinition
          include ParameterizedDefinition

          GRANULARITIES_MAP = {
            daily: :day,
            weekly: :week,
            monthly: :month,
            yearly: :year
          }.with_indifferent_access.freeze

          DEFAULT_GRANULARITY = :monthly

          def to_outer_arel(context)
            granularity = instance_parameter(:granularity, context[name]) || DEFAULT_GRANULARITY
            granularity = GRANULARITIES_MAP[granularity]

            context[:scope].func('toStartOfInterval', [super, Arel.sql("INTERVAL 1 #{granularity}")])
          end
        end
      end
    end
  end
end
