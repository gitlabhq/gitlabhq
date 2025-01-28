# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Models
    module Ci
      class FinishedPipelinesBase < ClickHouse::Models::BaseModel
        def self.time_window_valid?(from_time, to_time)
          raise NotImplementedError, "subclasses of #{self.class.name} must implement #{__method__}"
        end

        def self.validate_time_window(from_time, to_time)
          raise NotImplementedError, "subclasses of #{self.class.name} must implement #{__method__}"
        end

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

        def for_source(source)
          where(source: source)
        end

        def for_ref(ref)
          where(ref: ref)
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
          group(@query_builder.table[:status])
        end

        def group_by_timestamp_bin
          group(timestamp_alias)
        end

        def timestamp_bin_function(time_series_period)
          Arel::Nodes::NamedFunction.new(
            'dateTrunc',
            [
              Arel::Nodes.build_quoted(time_series_period.to_s),
              @query_builder.table[:started_at_bucket],
              timezone
            ]
          ).as(timestamp_alias)
        end

        def count_pipelines_function
          Arel::Nodes::NamedFunction.new('countMerge', [@query_builder.table[:count_pipelines]])
        end

        def duration_quantile_function(quantile)
          Arel::Nodes::NamedFunction
            .new("quantileMerge(#{quantile / 100.0})", [@query_builder.table[:duration_quantile]])
            .as("p#{quantile}")
        end

        private

        def format_time(date)
          Arel::Nodes::NamedFunction.new('toDateTime64', [
            Arel::Nodes::SqlLiteral.new(date.utc.strftime("'%Y-%m-%d %H:%M:%S'")),
            6,
            timezone
          ])
        end

        def timestamp_alias
          Arel.sql('timestamp')
        end

        def timezone
          Arel::Nodes.build_quoted('UTC')
        end
      end
    end
  end
end
