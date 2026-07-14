# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- existing module
  module Finders
    module Ci
      # Siphon-backed equivalent of FinishedBuildsDeduplicatedFinder. Reads
      # finished builds from siphon_p_ci_builds, with optional joins to
      # siphon_p_ci_pipelines (source/ref filtering) and siphon_p_ci_stages
      # (stage_name) that callers opt into via #filter_by_pipeline_attrs and
      # #with_stages.

      # rubocop: disable CodeReuse/ActiveRecord -- Clickhouse finder
      class SiphonFinishedBuildsFinder
        include ActiveRecord::Sanitization::ClassMethods
        include Concerns::FinishedBuildsAggregations

        TABLE_NAME = 'siphon_p_ci_builds'
        SUBQUERY_ALIAS = 'finished_builds'
        STAGES_SUBQUERY_ALIAS = SiphonStagesFinder::SUBQUERY_ALIAS

        # Mirrors the existing flow, which only seeds ci_finished_builds for
        # builds that reached a completed status (see Ci::Build's transition to
        # Ci::BuildFinishedWorker). siphon_p_ci_builds holds every build, so we
        # filter here to keep results consistent with the legacy finder.
        FINISHED_STATUSES = ::Ci::HasStatus::COMPLETED_STATUSES.freeze

        # Columns argMax-projected when the caller never calls #select. The
        # always-required columns (_siphon_deleted, type, status) are added by
        # finalize_inner_query.
        DEFAULT_ARG_MAX_COLUMNS = %i[
          traversal_path commit_id name stage_id started_at finished_at
        ].freeze

        delegate :to_sql, :to_redacted_sql, to: :final_query
        attr_reader :query_builder

        def self.for_container(container)
          new.for_container(container)
        end

        def initialize(inner_query: nil, outer_query: nil, selected_fields: [])
          @inner_query = inner_query || base_inner_query
          @query_builder = @outer_query = outer_query || base_outer_query
          @selected_fields = Array(selected_fields).flatten.compact.uniq
        end

        def execute
          ::ClickHouse::Client.select(final_query, :main)
        end

        def for_container(container)
          with_inner_query(inner_query.where(container_condition(container)))
        end

        # Applies conditions to the raw pre-dedup rows (before the argMax over
        # _siphon_replicated_at). Safe for values that are immutable across
        # replicated versions. For values that can change between
        # versions, add a dedicated argMax/HAVING-based method (see
        # #filter_by_job_name) instead of using #where.
        def where(conditions)
          with_inner_query(inner_query.where(conditions))
        end

        # Opt-in LEFT JOIN to siphon_p_ci_stages, the way a caller would join an
        # association in ActiveRecord. Required before selecting/grouping/ordering
        # on :stage_name. The container scopes the stages side and is consumed
        # here, so nothing about the join needs to be carried until #final_query.
        def with_stages(container)
          with_queries(
            inner_query: inner_query.select(*fields_with_arg_max(:stage_id)),
            outer_query: stage_join(outer_query, container)
          )
        end

        def select(*fields)
          fields = Array(fields).flatten.compact
          return self if fields.empty?

          validate_columns!(fields, :select)

          new_outer = fields.reduce(outer_query) { |query, field| query.select(select_expression_for(field)) }
          new_inner = inner_query.select(*fields_with_arg_max(*inner_fields_for(fields)))

          with_queries(
            inner_query: new_inner,
            outer_query: new_outer,
            selected_fields: (selected_fields + fields).uniq
          ).group_by(*fields)
        end

        def filter_by_job_name(term)
          condition = inner_query.named_func(
            'argMax', [inner_query[:name], inner_query[:_siphon_replicated_at]]
          ).matches("%#{sanitize_sql_like(term.downcase)}%")

          with_inner_query(inner_query.having(condition))
        end

        # started_at is immutable post-assignment, so pushing both bounds into
        # the inner WHERE lets the by_traversal_path_started_at projection prune
        # granules without changing results.
        def within_dates(from_time, to_time)
          inner = inner_query
          inner = inner.where(inner[:started_at].gteq(format_datetime64(from_time))) if from_time
          inner = inner.where(inner[:started_at].lt(format_datetime64(to_time))) if to_time
          with_inner_query(inner)
        end

        def limit(count)
          with_outer_query(outer_query.limit(count))
        end

        def offset(count)
          with_outer_query(outer_query.offset(count))
        end

        # When neither source nor ref is set the pipeline join adds no value:
        # the build row's own traversal_path already pins it to the container.
        def filter_by_pipeline_attrs(container:, from_time: nil, to_time: nil, source: nil, ref: nil)
          return self unless source || ref

          super(project: container, from_time: from_time, to_time: to_time, source: source, ref: ref)
        end

        def final_query
          base = outer_query
            .where(outer_query[:_siphon_deleted].eq(0))
            .where(type: 'Ci::Build')
            .where(status: FINISHED_STATUSES)

          with_builds_cte(base, finalize_inner_query)
        end

        private

        attr_reader :inner_query, :outer_query, :selected_fields

        def container_condition(container)
          if container.is_a?(Project)
            path = container.project_namespace.traversal_path(with_organization: true)
            inner_query[:traversal_path].eq(path)
          else
            path = container.traversal_path(with_organization: true)
            inner_query.func('startsWith', [inner_query[:traversal_path], inner_query.quote(path)])
          end
        end

        def base_inner_query
          ClickHouse::Client::QueryBuilder.new(TABLE_NAME)
            .select(:id, :partition_id)
            .group(:id, :partition_id)
        end

        def base_outer_query
          ClickHouse::Client::QueryBuilder.new(SUBQUERY_ALIAS)
        end

        # _siphon_deleted, type and status are always needed by the outer WHERE,
        # so project them unconditionally. Add the default column set when the
        # caller never invoked #select.
        def finalize_inner_query
          base = selected_fields.empty? ? default_inner_query : inner_query
          base.select(*fields_with_arg_max(:_siphon_deleted, :type, :status))
        end

        def default_inner_query
          inner_query.select(*fields_with_arg_max(*DEFAULT_ARG_MAX_COLUMNS))
        end

        def with_inner_query(new_inner)
          with_queries(inner_query: new_inner)
        end

        def with_outer_query(new_outer)
          with_queries(outer_query: new_outer)
        end

        def with_queries(inner_query: @inner_query, outer_query: @outer_query, selected_fields: @selected_fields)
          self.class.new(
            inner_query: inner_query,
            outer_query: outer_query,
            selected_fields: selected_fields
          )
        end

        def fields_with_arg_max(*fields)
          fields.uniq.map do |field|
            inner_query.named_func(
              'argMax', [inner_query[field], inner_query[:_siphon_replicated_at]]
            ).as(field.to_s)
          end
        end

        # :stage_name lives on the joined stages alias; everything else falls
        # back to the concern's finished_builds subquery expression.
        def field_expression(field)
          field == :stage_name ? stage_name_expr : super
        end

        def select_expression_for(field)
          return Arel.sql("#{stage_name_expr} AS stage_name") if field == :stage_name

          field
        end

        # Referencing :stage_name requires the stages alias, which only exists
        # after #with_stages. Guard here so misuse fails loudly at build time
        # instead of emitting SQL against a non-existent alias at execution.
        def stage_name_expr
          unless stages_joined?
            raise ArgumentError, 'call #with_stages(container) before selecting, grouping or ordering by :stage_name'
          end

          Arel.sql("`#{STAGES_SUBQUERY_ALIAS}`.`name`")
        end

        # Derive the stages-join state from the query itself rather than tracking
        # it separately: #with_stages adds a join targeting the stages alias.
        def stages_joined?
          outer_query.manager.join_sources.any? do |join|
            source = join.left
            source.is_a?(Arel::Nodes::TableAlias) && source.right.to_s == STAGES_SUBQUERY_ALIAS
          end
        end

        # stage_name resolves to the joined stages alias, but the join needs
        # stage_id from the inner subquery.
        def inner_fields_for(fields)
          fields.flat_map { |f| f == :stage_name ? [:stage_id] : [f] }.uniq
        end

        def add_aggregation_select(expression, requires_fields: [])
          new_inner = requires_fields.reduce(inner_query) do |query, field|
            query.select(*fields_with_arg_max(field))
          end

          with_queries(inner_query: new_inner, outer_query: outer_query.select(expression))
        end

        def apply_order(field, direction)
          target = field == :stage_name ? stage_name_expr : field
          with_outer_query(outer_query.order(target, direction))
        end

        # Reached only when callers bypass #group_by.
        def apply_group(*columns)
          with_outer_query(outer_query.group(*columns))
        end

        def apply_pipeline_filter(pipelines)
          with_inner_query(inner_query.where(commit_id: pipelines.select(:id).final_query))
        end

        def pipelines_finder
          ::ClickHouse::Finders::Ci::SiphonPipelinesFinder
        end

        # siphon_p_ci_builds has no `duration` column, so derive it from the
        # timestamps; the always-required argMax columns shift accordingly.
        # Builds without usable timestamps resolve to NULL rather than 0 so avg and
        # quantile exclude them, matching the legacy finder's null `duration`.
        def duration_expression
          started = outer_query[:started_at]
          finished = outer_query[:finished_at]

          condition = started.not_eq(nil).and(finished.not_eq(nil)).and(finished.gt(started))
          age = outer_query.named_func('age', [outer_query.quote('ms'), started, finished])

          outer_query.named_func('if', [condition, age, Arel.sql('NULL')])
        end

        def duration_requires_fields
          %i[started_at finished_at]
        end

        # Attach the deduplicated builds inner subquery as a CTE so the outer
        # FROM and the stages IN-subquery reference it by name instead of
        # textually duplicating it. ClickHouse expands the CTE inline, so this
        # is functionally equivalent but emits ~half the SQL.
        def with_builds_cte(outer, inner)
          outer.with(inner.as_cte(SUBQUERY_ALIAS))
        end

        # Scope the stages subquery by container only. Scoping it further by the
        # stage_ids from the builds CTE looks cheaper but references the CTE a
        # second time, and ClickHouse inlines CTEs at every reference site - the
        # whole builds dedup aggregation would run twice and block the main scan
        # behind a CreatingSets step (measured 6x slower on a 90-day window).
        def stage_join(base_outer, container)
          stages = SiphonStagesFinder.for_container(container)
          stages_alias = stages.final_query.to_arel.as(STAGES_SUBQUERY_ALIAS)
          stages_id = Arel::Table.new(STAGES_SUBQUERY_ALIAS)[:id]

          base_outer.joins(stages_alias, { stage_id: stages_id }, type: :outer)
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
