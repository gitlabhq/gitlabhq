# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Aggregated
        module StageQueryHelpers
          def percentile_cont
            percentile_cont_ordering = Arel::Nodes::UnaryOperation.new(Arel::Nodes::SqlLiteral.new('ORDER BY'), duration)
            Arel::Nodes::NamedFunction.new(
              'percentile_cont(0.5) WITHIN GROUP',
              [percentile_cont_ordering]
            )
          end

          def duration
            if in_progress?
              Arel::Nodes::Subtraction.new(
                Arel::Nodes::NamedFunction.new('TO_TIMESTAMP', [Time.current.to_i]),
                query.model.arel_table[:start_event_timestamp]
              )
            else
              calculate_duration
            end
          end

          def in_progress?
            params[:end_event_filter] == :in_progress
          end

          def duration_in_seconds(duration_expression = duration)
            Arel::Nodes::NamedFunction.new('CAST', [Arel::Nodes::Extract.new(duration_expression, :epoch).as('double precision')])
          end

          private

          def calculate_duration
            # Cast the duration_in_milliseconds bigint column to interval. We divide the
            # duration by 1000 thus we get a double precision number (seconds). The division is necessary
            # to avoid query errors for very long duration values.
            # Reason: Interval is parsed as a 32 bit integer and when the duration_in_milliseconds has
            # a very high value the parsing will fail.
            column = "#{query.model.quoted_table_name}.duration_in_milliseconds / 1000.0 || ' seconds'"
            Arel::Nodes::NamedFunction.new('CAST', [Arel.sql("(#{column}) AS interval")])
          end
        end
      end
    end
  end
end
