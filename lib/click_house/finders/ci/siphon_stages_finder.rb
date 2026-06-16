# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- existing module
  module Finders
    module Ci
      # Siphon-backed finder for siphon_p_ci_stages.
      #
      # siphon_p_ci_stages is a ReplacingMergeTree replica of p_ci_stages.
      # Each PG-side write (insert, update, soft-delete) appends a new
      # physical row with an incremented `_siphon_replicated_at`. Until
      # background merges run, the table can hold multiple rows per
      # (id, partition_id) - one for each replicated version.
      #
      # This finder uses the inner/outer pattern (same as SiphonPipelinesFinder):
      #
      #   inner query  - GROUP BY (id, partition_id) and argMax the columns
      #                  by _siphon_replicated_at to collapse each row to its
      #                  latest version. (id, partition_id) is the composite
      #                  PG primary key; grouping on id alone would collapse
      #                  rows from different partitions.
      #   outer query  - filters out rows whose latest version was soft-deleted
      #                  and is the surface callers SELECT / project from.

      # rubocop: disable CodeReuse/ActiveRecord -- Clickhouse finder
      class SiphonStagesFinder < ::ClickHouse::Client::QueryLike
        TABLE_NAME = 'siphon_p_ci_stages'
        SUBQUERY_ALIAS = 'stages'

        DEDUP_COLUMNS = %i[
          traversal_path
          pipeline_id
          name
          _siphon_deleted
        ].freeze

        delegate :to_sql, :to_redacted_sql, to: :final_query

        attr_reader :inner_query, :outer_query

        def self.for_project(project)
          new.for_project(project)
        end

        def initialize(inner_query: nil, outer_query: nil)
          @inner_query = inner_query || base_inner_query
          @outer_query = outer_query || base_outer_query
        end

        def for_project(project)
          path = project.project_namespace.traversal_path(with_organization: true)

          with_inner(inner_query.where(traversal_path: path))
        end

        def for_ids(ids)
          ids = Array(ids).compact
          return self if ids.empty?

          with_inner(inner_query.where(id: ids))
        end

        def select(*fields)
          with_outer(outer_query.select(*fields))
        end

        def final_query
          outer_query
            .where(outer_query[:_siphon_deleted].eq(0))
            .from(inner_query, SUBQUERY_ALIAS)
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
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
