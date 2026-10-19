# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- existing module
  module Finders
    module Ci
      # ClickHouse finder for siphon_ci_pipeline_metadata, the Siphon replica of
      # ci_pipeline_metadata that holds the pipeline `name`. Same inner (argMax
      # dedup) / outer (soft-delete filter) pattern as SiphonStagesFinder.

      # rubocop: disable CodeReuse/ActiveRecord -- Clickhouse finder
      class SiphonPipelineMetadataFinder < ::ClickHouse::Client::QueryLike
        include Concerns::SiphonQueryHelpers

        TABLE_NAME = 'siphon_ci_pipeline_metadata'
        SUBQUERY_ALIAS = 'pipeline_metadata'

        DEDUP_COLUMNS = %i[
          traversal_path
          name
          _siphon_deleted
        ].freeze

        NULLABLE_DEDUP_COLUMNS = %i[name].freeze

        delegate :to_sql, :to_redacted_sql, to: :final_query

        attr_reader :inner_query, :outer_query

        def self.for_container(container)
          new.for_container(container)
        end

        def initialize(inner_query: nil, outer_query: nil)
          @inner_query = inner_query || base_inner_query
          @outer_query = outer_query || base_outer_query
        end

        def for_container(container)
          with_inner(inner_query.where(container_condition(inner_query, container)))
        end

        # pipeline_id is immutable per metadata row, so filtering the raw
        # pre-dedup rows is safe.
        def for_pipeline_ids(ids)
          with_inner(inner_query.where(pipeline_id: ids))
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

        # pipeline_id alone is the PG primary key. Adding partition_id to the
        # GROUP BY would fan out the pipelines join if a row changes partition.
        def base_inner_query
          inner = ClickHouse::Client::QueryBuilder.new(TABLE_NAME)
            .select(:pipeline_id)
            .group(:pipeline_id)

          DEDUP_COLUMNS.each do |col|
            inner = inner.select(latest_value(inner, col).as(col.to_s))
          end
          inner
        end

        # argMax skips NULLs, so a NULL latest value would fall back to an older
        # one. Round-tripping through '' keeps the latest value at plain argMax
        # cost (a tuple wrapper also works but uses more memory).
        def latest_value(inner, col)
          version = inner[:_siphon_replicated_at]
          return inner.named_func('argMax', [inner[col], version]) unless NULLABLE_DEDUP_COLUMNS.include?(col)

          empty = inner.quote('')
          latest = inner.named_func('argMax', [inner.named_func('ifNull', [inner[col], empty]), version])
          inner.named_func('nullIf', [latest, empty])
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
