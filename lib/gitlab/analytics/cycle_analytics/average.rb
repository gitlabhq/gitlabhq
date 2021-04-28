# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class Average
        include Gitlab::Utils::StrongMemoize
        include StageQueryHelpers

        def initialize(stage:, query:, params: {})
          @stage = stage
          @query = query
          @params = params
        end

        def seconds
          select_average ? select_average['average'] : nil
        end

        def days
          seconds ? seconds.fdiv(1.day) : nil
        end

        private

        attr_reader :stage, :params

        # rubocop: disable CodeReuse/ActiveRecord
        def select_average
          strong_memoize(:select_average) do
            execute_query(@query.select(average_in_seconds.as('average')).reorder(nil)).first
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def average
          Arel::Nodes::NamedFunction.new(
            'AVG',
            [duration]
          )
        end

        def average_in_seconds
          Arel::Nodes::Extract.new(average, :epoch)
        end
      end
    end
  end
end
