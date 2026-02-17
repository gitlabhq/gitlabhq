# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Finders
    module Ci
      module Concerns
        module FinishedBuildsAggregations
          extend ActiveSupport::Concern

          ALLOWED_TO_GROUP = %i[name stage_name].freeze
          ALLOWED_TO_SELECT = %i[name stage_name].freeze
          ALLOWED_AGGREGATIONS = %i[
            mean_duration
            p50_duration
            p75_duration
            p90_duration
            p95_duration
            p99_duration
            rate_of_success
            rate_of_failed
            rate_of_canceled
            rate_of_skipped
            count_success
            count_failed
            count_canceled
            count_skipped
            total_count
          ].freeze
          ALLOWED_TO_ORDER = (ALLOWED_TO_SELECT + ALLOWED_AGGREGATIONS).freeze
          STATUS = %w[success failed canceled skipped].freeze
          ALLOWED_PERCENTILES = [50, 75, 90, 95, 99].freeze

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

          included do
            STATUS.each do |status|
              define_method(:"rate_of_#{status}") do
                rate_of_status(status)
              end

              define_method(:"count_#{status}") do
                count_of_status(status)
              end
            end

            ALLOWED_PERCENTILES.each do |percentile|
              define_method(:"p#{percentile}_duration") do
                duration_of_percentile(percentile)
              end
            end
          end

          def select_aggregations(*aggregations)
            validate_columns!(aggregations, :aggregate)

            aggregations.reduce(self) do |query, aggregation|
              query.method(aggregation).call
            end
          end

          def mean_duration
            add_aggregation_select(
              round(ms_to_s(query_builder.avg(:duration))).as("mean_duration"),
              requires_fields: [:duration]
            )
          end

          def total_count
            add_aggregation_select(
              query_builder.count.as("total_count")
            )
          end

          def order_by(field, direction = :asc)
            validate_columns!(field, :order)

            order_target = aggregate?(field) ? Arel.sql(field.to_s) : field
            apply_order(order_target, direction)
          end

          def group_by(*fields)
            validate_columns!(fields, :group)

            apply_group(*fields.map { |f| query_builder[f] }.uniq)
          end

          def filter_by_pipeline_attrs(project:, from_time: nil, to_time: nil, source: nil, ref: nil)
            pipelines = ::ClickHouse::Models::Ci::FinishedPipeline
                          .for_container(project)
                          .within_dates(from_time, to_time)

            pipelines = pipelines.for_source(source) if source
            pipelines = pipelines.for_ref(ref) if ref

            apply_pipeline_filter(pipelines)
          end

          private

          def validate_columns!(fields, operation)
            invalid_columns = Array(fields) - ALLOWED_COLUMNS_BY_OPERATION[operation]
            return if invalid_columns.empty?

            raise ArgumentError, format(ERROR_MESSAGES[operation],
              column: invalid_columns.first,
              columns: invalid_columns)
          end

          def rate_of_status(status)
            add_aggregation_select(
              build_rate_aggregate(status),
              requires_fields: [:status]
            )
          end

          def build_rate_aggregate(status)
            percentage = query_builder.division(build_count_aggregate(status), query_builder.count)
            percentage_value = query_builder.multiply(percentage, 100)

            round(percentage_value).as("rate_of_#{status}")
          end

          def count_of_status(status)
            add_aggregation_select(
              build_count_aggregate(status).as("count_#{status}"),
              requires_fields: [:status]
            )
          end

          def build_count_aggregate(status)
            query_builder.count_if(
              query_builder.equality(:status, Arel::Nodes.build_quoted(status))
            )
          end

          def duration_of_percentile(percentile)
            add_aggregation_select(
              round(ms_to_s(query_builder.quantile(percentile.to_f / 100.0, :duration))).as("p#{percentile}_duration"),
              requires_fields: [:duration]
            )
          end

          def aggregate?(field)
            ALLOWED_AGGREGATIONS.include?(field.to_sym)
          end

          def round(node, precision = 2)
            query_builder.named_func("round", [node, precision])
          end

          def ms_to_s(node)
            query_builder.division(node, 1000.0)
          end
        end
      end
    end
  end
end
