# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class DateBucketDimension < DimensionDefinition
          include ParameterizedDefinition

          self.supported_parameters = %i[granularity]

          GRANULARITIES_MAP = {
            daily: :day,
            weekly: :week,
            monthly: :month,
            yearly: :year
          }.with_indifferent_access.freeze

          DEFAULT_GRANULARITY = :monthly

          def validate_part(part)
            super
            validate_granularity(part)
          end

          def to_outer_arel(context)
            granularity = instance_parameter(:granularity, context[name]) || DEFAULT_GRANULARITY
            granularity = GRANULARITIES_MAP[granularity]

            context[:scope].func('toStartOfInterval', [super, Arel.sql("INTERVAL 1 #{granularity}")])
          end

          private

          def validate_granularity(part)
            granularity = instance_parameter(:granularity, part.configuration)
            return unless granularity
            return if granularity.in?(parameters.dig(:granularity, :in) || [])

            part.errors.add(:granularity,
              format(s_("AggregationEngine|Unknown granularity \"%{granularity}\""),
                granularity: granularity)
            )
          end
        end
      end
    end
  end
end
