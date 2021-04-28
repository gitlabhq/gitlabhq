# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class Sorting
        include StageQueryHelpers

        def initialize(stage:, query:, params: {})
          @stage = stage
          @query = query
          @params = params
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def apply(sort, direction)
          sorting_options = {
            end_event: {
              asc: -> { query.reorder(end_event_timestamp_projection.asc) },
              desc: -> { query.reorder(end_event_timestamp_projection.desc) }
            },
            duration: {
              asc: -> { query.reorder(duration.asc) },
              desc: -> { query.reorder(duration.desc) }
            }
          }

          sort_lambda = sorting_options.dig(sort, direction) || sorting_options.dig(:end_event, :desc)
          sort_lambda.call
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        attr_reader :stage, :query, :params
      end
    end
  end
end
