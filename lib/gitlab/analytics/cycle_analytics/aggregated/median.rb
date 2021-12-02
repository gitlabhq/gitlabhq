# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Aggregated
        class Median
          include StageQueryHelpers

          def initialize(stage:, query:, params:)
            @stage = stage
            @query = query
            @params = params
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def seconds
            @query = @query.select(duration_in_seconds(percentile_cont).as('median')).reorder(nil)
            result = @query.take || {}

            result['median'] || nil
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def days
            seconds ? seconds.fdiv(1.day) : nil
          end

          private

          attr_reader :stage, :query, :params
        end
      end
    end
  end
end
