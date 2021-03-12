# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class Sorting
        # rubocop: disable CodeReuse/ActiveRecord
        SORTING_OPTIONS = {
          end_event: {
            asc: -> (query, stage) { query.reorder(stage.end_event.timestamp_projection.asc) },
            desc: -> (query, stage) { query.reorder(stage.end_event.timestamp_projection.desc) }
          }.freeze,
          duration: {
            asc: -> (query, stage) { query.reorder(Arel::Nodes::Subtraction.new(stage.end_event.timestamp_projection, stage.start_event.timestamp_projection).asc) },
            desc: -> (query, stage) { query.reorder(Arel::Nodes::Subtraction.new(stage.end_event.timestamp_projection, stage.start_event.timestamp_projection).desc) }
          }.freeze
        }.freeze
        # rubocop: enable CodeReuse/ActiveRecord,

        def self.apply(query, stage, sort, direction)
          sort_lambda = SORTING_OPTIONS.dig(sort, direction) || SORTING_OPTIONS.dig(:end_event, :desc)
          sort_lambda.call(query, stage)
        end
      end
    end
  end
end
