# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class Median
        include StageQueryHelpers

        def initialize(stage:, query:)
          @stage = stage
          @query = query
        end

        def seconds
          @query = @query.select(median_duration_in_seconds.as('median'))
          result = execute_query(@query).first || {}

          result['median'] ? result['median'].to_i : nil
        end

        def days
          seconds ? seconds.fdiv(1.day) : nil
        end

        private

        attr_reader :stage

        def percentile_cont
          percentile_cont_ordering = Arel::Nodes::UnaryOperation.new(Arel::Nodes::SqlLiteral.new('ORDER BY'), duration)
          Arel::Nodes::NamedFunction.new(
            'percentile_cont(0.5) WITHIN GROUP',
            [percentile_cont_ordering]
          )
        end

        def median_duration_in_seconds
          Arel::Nodes::Extract.new(percentile_cont, :epoch)
        end
      end
    end
  end
end
