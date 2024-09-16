# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Models
    module Ci
      class FinishedPipelinesBase < ClickHouse::Models::BaseModel
        def self.for_project(project)
          new.for_project(project)
        end

        def self.by_status(statuses)
          new.by_status(statuses)
        end

        def self.group_by_status
          new.group_by_status
        end

        def for_project(project)
          where(path: project.project_namespace.traversal_path)
        end

        def within_dates(from_time, to_time)
          query = self
          started_at_bucket = @query_builder.table[:started_at_bucket]

          # rubocop: disable CodeReuse/ActiveRecord -- this is a ClickHouse model
          query = query.where(started_at_bucket.gteq(format_time(from_time))) if from_time
          query = query.where(started_at_bucket.lt(format_time(to_time))) if to_time
          # rubocop: enable CodeReuse/ActiveRecord

          query
        end

        def by_status(statuses)
          where(status: statuses)
        end

        def group_by_status
          group([@query_builder.table[:status]])
        end

        def count_pipelines_function
          Arel::Nodes::NamedFunction.new('countMerge', [@query_builder.table[:count_pipelines]])
        end

        private

        def format_time(date)
          Arel::Nodes::NamedFunction.new('toDateTime64', [
            Arel::Nodes::SqlLiteral.new(date.utc.strftime("'%Y-%m-%d %H:%M:%S'")),
            6,
            Arel::Nodes.build_quoted('UTC')
          ])
        end
      end
    end
  end
end
