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
              Arel::Nodes::Subtraction.new(
                query.model.arel_table[:end_event_timestamp],
                query.model.arel_table[:start_event_timestamp]
              )
            end
          end

          def in_progress?
            params[:end_event_filter] == :in_progress
          end

          def duration_in_seconds(duration_expression = duration)
            Arel::Nodes::NamedFunction.new('CAST', [Arel::Nodes::Extract.new(duration_expression, :epoch).as('double precision')])
          end
        end
      end
    end
  end
end
