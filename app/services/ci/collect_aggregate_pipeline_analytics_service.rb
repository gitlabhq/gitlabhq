# frozen_string_literal: true

module Ci
  class CollectAggregatePipelineAnalyticsService < CollectPipelineAnalyticsServiceBase
    extend ::Gitlab::Utils::Override

    private

    override :fetch_response
    def fetch_response
      query = base_query
      result = {}

      if status_groups.any?
        result[:count] = status_groups.index_with(0)
        calculate_aggregate_count(query, result[:count])
        calculate_aggregate_status_group_counts(query, result[:count])
      end

      calculate_aggregate_duration_percentiles(query, result)

      ServiceResponse.success(payload: { aggregate: result })
    rescue ::ClickHouse::Client::DatabaseError => e
      ServiceResponse.error(message: e.message)
    end

    def calculate_aggregate_count(query, result)
      return if status_groups.exclude?(:any)

      all_query = query.select(query.count_pipelines_function.as('all'))
      result[:any] = ::ClickHouse::Client.select(all_query.to_sql, :main).first['all']
    end

    def calculate_aggregate_status_group_counts(query, result)
      return unless status_groups.intersect?(STATUS_GROUPS)

      query = query
        .select(:status, query.count_pipelines_function.as('count'))
        .by_status(selected_statuses)
        .group_by_status

      result_by_status = ::ClickHouse::Client.select(query.to_sql, :main).map(&:values).to_h
      result_by_status.each_pair { |status, count| result[STATUS_TO_STATUS_GROUP[status]] += count }
    end

    def calculate_aggregate_duration_percentiles(query, result)
      return if duration_percentiles.empty?

      duration_query = query.select(*duration_percentiles.map { |p| query.duration_quantile_function(p) })
      duration_result = ::ClickHouse::Client.select(duration_query.to_sql, :main)
      result[:duration_statistics] = duration_result.first.symbolize_keys.transform_values do |interval|
        interval.to_f.round(3).seconds
      end
    end
  end
end
