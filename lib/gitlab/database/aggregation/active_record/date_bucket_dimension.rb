# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
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

          def to_arel(context)
            granularity = instance_parameter(:granularity, context[name]) || DEFAULT_GRANULARITY

            quoted_string = context[:scope].model.connection.quote(GRANULARITIES_MAP[granularity])

            expr = expression ? expression.call : context[:scope].arel_table[name]
            Arel::Nodes::NamedFunction.new('date_trunc', [Arel.sql(quoted_string), expr])
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
