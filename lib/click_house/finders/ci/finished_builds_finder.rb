# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Finders
    module Ci
      # todo: rename base_model to base_finder: https://gitlab.com/gitlab-org/gitlab/-/issues/559016
      class FinishedBuildsFinder < ::ClickHouse::Models::BaseModel
        include ActiveRecord::Sanitization::ClassMethods

        ALLOWED_TO_GROUP = %i[name stage_id].freeze
        ALLOWED_TO_SELECT = %i[name stage_id].freeze
        ALLOWED_AGGREGATIONS = %i[
          mean_duration_in_seconds
          p95_duration_in_seconds
          rate_of_success
          rate_of_failed
          rate_of_canceled
          rate_of_skipped
        ].freeze
        ALLOWED_TO_ORDER = (ALLOWED_TO_SELECT + ALLOWED_AGGREGATIONS).freeze
        STATUS = %w[success failed canceled skipped].freeze

        ERROR_MESSAGES = {
          select: "Cannot select columns: %{columns}. Allowed: #{ALLOWED_TO_SELECT.join(', ')}",
          aggregate: "Cannot aggregate columns: %{columns}. Allowed: #{ALLOWED_AGGREGATIONS.join(', ')}",
          group: "Cannot group by column: %{column}. Allowed: #{ALLOWED_TO_GROUP.join(', ')}",
          order: "Cannot order by column: %{column}. Allowed: #{ALLOWED_TO_ORDER.join(', ')}"
        }.freeze

        ALLOWED_COLUMNS_BY_OPERATION = {
          select: ALLOWED_TO_SELECT,
          aggregate: ALLOWED_AGGREGATIONS,
          group: ALLOWED_TO_GROUP,
          order: ALLOWED_TO_ORDER
        }.freeze

        def self.table_name
          model_class.table_name
        end

        def self.model_class
          ::ClickHouse::Models::Ci::FinishedBuild
        end

        def execute
          ::ClickHouse::Client.select(@query_builder, :main)
        end

        def for_project(project_id)
          where(project_id: project_id)
        end

        def select(*fields, aggregate: false)
          fields = Array(fields).flatten
          return self unless fields.any?

          validate_columns!(fields, :select, aggregate)

          query = super(*fields)
          aggregate ? query : query.group_by(*fields)
        end

        def select_aggregations(*aggregations)
          validate_columns!(aggregations, :aggregate)

          aggregations.reduce(self) do |query, aggregation|
            query.method(aggregation).call
          end
        end

        # Aggregation methods
        def mean_duration_in_seconds
          select(
            build_duration_aggregate('avg', 'mean_duration_in_seconds'),
            aggregate: true
          )
        end

        def p95_duration_in_seconds
          select(
            build_duration_aggregate('quantile(0.95)', 'p95_duration_in_seconds'),
            aggregate: true
          )
        end

        def rate_of_status(status = 'success')
          validate_status!(status)

          select(
            build_rate_aggregate(status),
            aggregate: true
          )
        end

        def order_by(field, direction = :asc)
          validate_columns!(field, :order)

          order_target = aggregate?(field) ? Arel.sql(field.to_s) : field
          order(order_target, direction)
        end

        def group_by(*fields)
          fields = Array(fields).flatten
          return self unless fields.any?

          validate_columns!(fields, :group)

          # Note: Aggregation can't be grouped, so using @query_builder.table directly.
          group(fields.map { |f| @query_builder.table[f] }.uniq)
        end

        # Meta methods for STATUSes
        STATUS.each do |status|
          define_method(:"rate_of_#{status}") do
            rate_of_status(status)
          end
        end

        def filter_by_job_name(term)
          where(query_builder.table[:name].matches("%#{sanitize_sql_like(term.downcase)}%"))
        end

        def filter_by_pipeline_attrs(project:, from_time: nil, to_time: nil, source: nil, ref: nil)
          pipelines = ::ClickHouse::Models::Ci::FinishedPipeline.for_container(project).within_dates(
            from_time, to_time)

          pipelines = pipelines.for_source(source) if source
          pipelines = pipelines.for_ref(ref) if ref

          where(pipeline_id: pipelines.select(:id).query_builder)
        end

        private

        def validate_columns!(fields, operation, aggregate = false)
          return if aggregate && operation == :select

          invalid_columns = Array(fields) - ALLOWED_COLUMNS_BY_OPERATION[operation]
          return if invalid_columns.empty?

          raise ArgumentError, format(ERROR_MESSAGES[operation],
            column: invalid_columns.first,
            columns: invalid_columns
          )
        end

        def validate_status!(status)
          return if STATUS.include?(status.to_s)

          raise ArgumentError, "Invalid status: #{status}. Must be one of: #{STATUS.join(', ')}"
        end

        def build_duration_aggregate(function, alias_name)
          duration_function = Arel::Nodes::NamedFunction.new(
            function,
            [@query_builder.table[:duration]]
          )

          Arel::Nodes::NamedFunction.new(
            'round',
            [
              Arel::Nodes::Division.new(
                duration_function,
                Arel::Nodes.build_quoted(1000.0)
              ),
              2
            ]
          ).as(alias_name)
        end

        def build_rate_aggregate(status)
          count_if = Arel::Nodes::NamedFunction.new(
            'countIf',
            [
              Arel::Nodes::Equality.new(
                @query_builder.table[:status],
                Arel::Nodes.build_quoted(status)
              )
            ]
          )

          total_count = Arel::Nodes::NamedFunction.new('count', [])

          Arel::Nodes::NamedFunction.new(
            'round',
            [
              Arel::Nodes::Multiplication.new(
                Arel::Nodes::Division.new(count_if, total_count),
                Arel::Nodes.build_quoted(100)
              ),
              2
            ]
          ).as("rate_of_#{status}")
        end

        def aggregate?(field)
          ALLOWED_AGGREGATIONS.include?(field.to_sym)
        end
      end
    end
  end
end
