# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        class TimestampColumn < Column
          include ParameterizedDefinition

          self.supported_parameters = %i[granularity]

          GRANULARITIES_MAP = {
            daily: :day,
            weekly: :week,
            monthly: :month,
            yearly: :year
          }.with_indifferent_access.freeze

          DEFAULT_GRANULARITY = :monthly

          def to_hash
            super.merge(kind: :timestamp_column)
          end

          def to_arel(context)
            granularity = instance_parameter(:granularity, context[name]) || DEFAULT_GRANULARITY

            # TODO: Validate granularity in query plan!

            quoted_string = context[:scope].model.connection.quote(GRANULARITIES_MAP[granularity])

            expr = expression ? expression.call : context[:scope].arel_table[name]
            Arel::Nodes::NamedFunction.new('date_trunc', [Arel.sql(quoted_string), expr])
          end
        end
      end
    end
  end
end
