# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Finders
    module Ci
      class FinishedBuildsDeduplicatedFinder
        include ActiveRecord::Sanitization::ClassMethods
        include Concerns::FinishedBuildsAggregations

        SUBQUERY_ALIAS = 'finished_builds'
        TABLE_NAME = 'ci_finished_builds'
        DEFAULT_ARG_MAX_COLUMNS = %i[
          project_id pipeline_id status duration name stage_name group_name
        ].freeze

        delegate :to_sql, :to_redacted_sql, to: :final_query
        attr_reader :query_builder

        def initialize(inner_query: nil, outer_query: nil, selected_fields: false)
          @inner_query = inner_query || base_inner_query
          @query_builder = @outer_query = outer_query || base_outer_query
          @selected_fields = selected_fields
        end

        def execute
          ::ClickHouse::Client.select(final_query, :main)
        end

        # rubocop: disable CodeReuse/ActiveRecord -- this is a ClickHouse query builder class using Arel
        def for_project(project_id)
          with_inner_query(inner_query.where(project_id: project_id))
        end

        def where(conditions)
          with_inner_query(inner_query.where(conditions))
        end

        def select(*fields)
          fields = Array(fields).flatten.compact
          return self if fields.empty?

          validate_columns!(fields, :select)

          with_queries(
            inner_query: inner_query.select(*fields_with_arg_max(*fields)),
            outer_query: outer_query.select(*fields),
            selected_fields: true
          ).group_by(*fields)
        end

        def filter_by_job_name(term)
          condition = inner_query.named_func(
            'argMax', [inner_query[:name], inner_query[:version]]
          ).matches("%#{sanitize_sql_like(term.downcase)}%")

          with_inner_query(inner_query.having(condition))
        end

        def filter_deleted(include_deleted: false)
          return self if include_deleted

          condition = inner_query.named_func(
            'argMax', [inner_query[:deleted], inner_query[:version]]
          ).eq(0)

          with_inner_query(inner_query.having(condition))
        end

        def limit(count)
          with_outer_query(outer_query.limit(count))
        end

        def offset(count)
          with_outer_query(outer_query.offset(count))
        end

        private

        attr_reader :inner_query, :outer_query, :selected_fields

        def base_inner_query
          ClickHouse::Client::QueryBuilder.new(TABLE_NAME).select(:id).group(:id)
        end

        def base_outer_query
          ClickHouse::Client::QueryBuilder.new(SUBQUERY_ALIAS)
        end

        def final_query
          inner = selected_fields ? inner_query : default_inner_query
          outer_query.from(inner, SUBQUERY_ALIAS)
        end

        def default_inner_query
          inner_query.select(*fields_with_arg_max(*DEFAULT_ARG_MAX_COLUMNS))
        end

        def with_inner_query(new_inner)
          self.class.new(inner_query: new_inner, outer_query: outer_query, selected_fields: selected_fields)
        end

        def with_outer_query(new_outer)
          self.class.new(inner_query: inner_query, outer_query: new_outer, selected_fields: selected_fields)
        end

        def with_queries(inner_query:, outer_query:, selected_fields:)
          self.class.new(inner_query: inner_query, outer_query: outer_query, selected_fields: selected_fields)
        end

        def fields_with_arg_max(*fields)
          fields.map do |field|
            inner_query.named_func('argMax', [inner_query[field], inner_query[:version]]).as(field.to_s)
          end
        end

        def add_aggregation_select(expression, requires_fields: [])
          new_inner = requires_fields.reduce(inner_query) do |query, field|
            query.select(*fields_with_arg_max(field))
          end

          with_queries(
            inner_query: new_inner,
            outer_query: outer_query.select(expression),
            selected_fields: selected_fields
          )
        end

        def apply_order(field, direction)
          with_outer_query(outer_query.order(field, direction))
        end

        def apply_group(*columns)
          with_outer_query(outer_query.group(*columns))
        end

        def apply_pipeline_filter(pipelines)
          with_inner_query(inner_query.where(pipeline_id: pipelines.select(:id).query_builder))
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
