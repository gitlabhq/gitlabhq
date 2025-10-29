# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        class TimestampColumn < Column
          attr_reader :granularities

          DEFAULT_GRANULARITY = :month

          def initialize(
            name, type, granularities: [DEFAULT_GRANULARITY], expression: nil, formatter: nil, scope_proc: nil,
            description: nil)
            @granularities = granularities.to_set
            super(name, type, expression:, formatter:, scope_proc:, description:)
          end

          def identifier
            :"timestamp_column_#{name}"
          end

          def to_hash
            super.merge(
              kind: :timestamp_column,
              granularities: granularities.to_a,
              default_granularity: DEFAULT_GRANULARITY
            )
          end

          def to_arel(context)
            granularity = context.dig(name, :granularity)
            # TODO: Use ActiveModel validation here
            raise "Unknown granularity: #{granularity}" unless granularities.include?(granularity)

            quoted_string = context[:scope].model.connection.quote(granularity)

            expr = expression ? expression.call : context[:arel_table][name]
            Arel::Nodes::NamedFunction.new('date_trunc', [Arel.sql(quoted_string), expr])
          end
        end
      end
    end
  end
end
