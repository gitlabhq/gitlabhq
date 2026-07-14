# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- existing module
  module Finders
    module Ci
      # Siphon-backed equivalent of FinishedPipelines{Hourly,Daily}. Reads
      # from siphon_p_ci_pipelines (ReplacingMergeTree replica of p_ci_pipelines).
      #
      # Inner subquery picks the latest version of each row via argMax over
      # _siphon_replicated_at; outer query filters out soft-deleted rows and
      # runs the aggregation. (Similar to FinishedBuildsDeduplicatedFinder)
      #
      # Notable column mappings vs the MV path: (Remove this note after `pipeline_analytics_siphon` removal)
      #   * path -> traversal_path (siphon stores it with the leading
      #     organization_id, so use traversal_path(with_organization: true))
      #   * started_at_bucket -> raw started_at
      #   * source string -> Ci::Pipeline.sources int enum

      # rubocop: disable CodeReuse/ActiveRecord -- Clickhouse finder
      class SiphonPipelinesFinder < ::ClickHouse::Client::QueryLike
        TABLE_NAME = 'siphon_p_ci_pipelines'
        SUBQUERY_ALIAS = 'pipelines'

        # Columns surfaced from the dedup subquery to the outer query.
        DEDUP_COLUMNS = %i[
          traversal_path
          status
          source
          ref
          started_at
          finished_at
          duration
          _siphon_deleted
        ].freeze

        # Siphon reads raw rows (no MV bucket budget), so we replace the
        # Hourly/Daily fallback ladder with a single 366-day cap that mirrors
        # FinishedPipelinesDaily's outer limit. Do NOT reintroduce the
        # 169-hour hourly cap here to mirror FinishedPipelinesHourly.
        TIME_BUCKETS_LIMIT = 366

        delegate :to_sql, :to_redacted_sql, to: :final_query

        attr_reader :inner_query, :outer_query

        def self.time_window_valid?(from_time, to_time)
          (to_time - from_time) / 1.day <= TIME_BUCKETS_LIMIT
        end

        def self.validate_time_window(from_time, to_time)
          return if time_window_valid?(from_time, to_time)

          "Maximum of #{TIME_BUCKETS_LIMIT} days can be requested"
        end

        def self.for_container(container)
          if container.is_a?(Project)
            new.for_project(container)
          else
            new.for_group(container)
          end
        end

        def self.by_status(statuses)
          new.by_status(statuses)
        end

        def self.group_by_status
          new.group_by_status
        end

        def initialize(inner_query: nil, outer_query: nil)
          @inner_query = inner_query || base_inner_query
          @outer_query = outer_query || base_outer_query
        end

        def for_project(project)
          path = project.project_namespace.traversal_path(with_organization: true)

          with_inner(inner_query.where(traversal_path: path))
        end

        def for_group(group)
          path = group.traversal_path(with_organization: true)
          condition = inner_query.func('startsWith', [inner_query[:traversal_path], inner_query.quote(path)])

          with_inner(inner_query.where(condition))
        end

        def for_subgroups(subgroups)
          return self if subgroups.empty?

          conditions = subgroups.map do |subgroup|
            path = subgroup.traversal_path(with_organization: true)
            inner_query.func('startsWith', [inner_query[:traversal_path], inner_query.quote(path)])
          end

          with_inner(inner_query.where(conditions.reduce { |left, right| left.or(right) }))
        end

        # --- date/source/ref filters ---
        #
        # started_at is pushed into the inner query so the by_traversal_path_started_at
        # projection can prune granules on the date range. This is functionally
        # equivalent to filtering on the outer (post-argMax) value because
        # started_at does not change across versions for a given pipeline.
        #
        # source / ref stay on the outer query - they are tiny enums / strings
        # not in any projection or PK, so granule pruning would not benefit.

        def within_dates(from_time, to_time)
          inner = inner_query
          inner = inner.where(inner[:started_at].gteq(format_time(from_time))) if from_time
          inner = inner.where(inner[:started_at].lt(format_time(to_time))) if to_time
          with_inner(inner)
        end

        def for_source(source)
          raise ArgumentError, "Unknown pipeline source: #{source.inspect}" unless ::Ci::Pipeline.sources.key?(source)

          with_outer(outer_query.where(source: ::Ci::Pipeline.sources[source]))
        end

        def for_ref(ref)
          with_outer(outer_query.where(ref: ref))
        end

        def by_status(statuses)
          with_outer(outer_query.where(status: statuses))
        end

        def group_by_status
          with_outer(outer_query.group(outer_query[:status]))
        end

        def group_by_timestamp_bin
          with_outer(outer_query.group(timestamp_alias))
        end

        def timestamp_bin_function(time_series_period)
          outer_query.func(
            'dateTrunc',
            [
              outer_query.quote(time_series_period.to_s),
              outer_query[:started_at],
              timezone
            ]
          ).as(timestamp_alias)
        end

        def count_pipelines_function
          outer_query.func('count', [])
        end

        def duration_quantile_function(quantile)
          outer_query.func("quantile(#{quantile / 100.0})", [outer_query[:duration]])
            .as("p#{quantile}")
        end

        def select(*fields)
          with_outer(outer_query.select(*fields))
        end

        # Required by ClickHouse::Client.select - accepts QueryLike objects.
        def final_query
          # Always exclude rows whose latest version was soft-deleted.
          outer_with_soft_delete = outer_query.where(_siphon_deleted: false)
          outer_with_soft_delete.from(inner_query, SUBQUERY_ALIAS)
        end

        private

        def base_inner_query
          inner = ClickHouse::Client::QueryBuilder.new(TABLE_NAME)
            .select(:id, :partition_id)
            .group(:id, :partition_id)

          DEDUP_COLUMNS.each do |col|
            inner = inner.select(
              inner.named_func('argMax', [inner[col], inner[:_siphon_replicated_at]]).as(col.to_s)
            )
          end
          inner
        end

        def base_outer_query
          ClickHouse::Client::QueryBuilder.new(SUBQUERY_ALIAS)
        end

        def with_inner(new_inner)
          self.class.new(inner_query: new_inner, outer_query: outer_query)
        end

        def with_outer(new_outer)
          self.class.new(inner_query: inner_query, outer_query: new_outer)
        end

        def format_time(date)
          outer_query.func(
            'toDateTime64',
            [outer_query.quote(date.utc.strftime('%Y-%m-%d %H:%M:%S')), 6, timezone]
          )
        end

        def timestamp_alias
          'timestamp'
        end

        def timezone
          outer_query.quote('UTC')
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
