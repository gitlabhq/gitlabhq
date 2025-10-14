# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing clickHouse module
  module Models
    module Ci
      class FinishedPipeline < FinishedPipelinesBase
        def self.table_name
          'ci_finished_pipelines'
        end

        def within_dates(from_time, to_time)
          query = self
          started_at = @query_builder.table[:started_at]

          # rubocop: disable CodeReuse/ActiveRecord -- this is a ClickHouse model
          query = query.where(started_at.gteq(format_time(from_time))) if from_time
          query = query.where(started_at.lt(format_time(to_time))) if to_time
          # rubocop: enable CodeReuse/ActiveRecord

          query
        end
      end
    end
  end
end
