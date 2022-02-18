# frozen_string_literal: true

module Gitlab
  module Usage
    class ServicePingReport
      class << self
        def for(output:, cached: false)
          case output.to_sym
          when :all_metrics_values
            all_metrics_values(cached)
          when :metrics_queries
            metrics_queries
          when :non_sql_metrics_values
            non_sql_metrics_values
          end
        end

        private

        def all_metrics_values(cached)
          Rails.cache.fetch('usage_data', force: !cached, expires_in: 2.weeks) do
            Gitlab::UsageData.data
          end
        end

        def metrics_queries
          Gitlab::UsageDataQueries.data
        end

        def non_sql_metrics_values
          Gitlab::UsageDataNonSqlMetrics.data
        end
      end
    end
  end
end
