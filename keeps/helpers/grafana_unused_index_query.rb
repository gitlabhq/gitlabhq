# frozen_string_literal: true

require_relative '../../lib/grafana/client'

module Keeps
  module Helpers
    # Queries Mimir via the Grafana datasource proxy, one PromQL request per
    # (table, cluster) pair. `unused?` returns true (zero activity), false
    # (has activity), or nil (no signal: unreachable, failed, or no series).
    class GrafanaUnusedIndexQuery
      LOOKBACK_DAYS = 10
      LOOKBACK = "#{LOOKBACK_DAYS}d".freeze
      API_URL_ENV = 'GITLAB_GRAFANA_API_URL'
      API_KEY_ENV = 'GITLAB_GRAFANA_API_KEY'
      DATASOURCE_UID_ENV = 'GITLAB_GRAFANA_DATASOURCE_UID'
      # `env=` label on postgres-exporter metrics. Set to 'gstg' alongside the
      # staging datasource UID when testing against the staging Mimir.
      QUERY_ENV_ENV = 'GITLAB_GRAFANA_ENV'
      DEFAULT_QUERY_ENV = 'gprd'

      def initialize
        @api_url = ENV[API_URL_ENV]
        @api_key = ENV[API_KEY_ENV]
        @datasource_uid = ENV[DATASOURCE_UID_ENV]
        @query_env = ENV.fetch(QUERY_ENV_ENV, DEFAULT_QUERY_ENV)
        @cache = {}
      end

      def available?
        @api_url.present? && @api_key.present? && @datasource_uid.present?
      end

      def unused?(table:, type:, indexrelname:)
        result = unused_indexes_for(table: table, type: type)
        return if result.nil?

        result.include?(indexrelname)
      end

      private

      def unused_indexes_for(table:, type:)
        cache_key = [table, type]
        return @cache[cache_key] if @cache.key?(cache_key)

        @cache[cache_key] = fetch_unused_indexes(table, type)
      end

      def fetch_unused_indexes(table, type)
        response = client.proxy_datasource(
          datasource_id: "uid/#{@datasource_uid}",
          proxy_path: 'api/v1/query',
          query: { query: promql_for(table, type), time: Time.now.to_i }
        )

        parsed = Gitlab::Json.safe_parse(response.body) || {}
        return unless parsed['status'] == 'success'

        Array(parsed.dig('data', 'result')).each_with_object(Set.new) do |entry, set|
          name = entry.dig('metric', 'indexrelname')
          set << name if name
        end
      rescue Grafana::Client::Error => e
        # Outage maps to nil (no signal) so the Keep skips conservatively; the
        # next scheduled run retries.
        warn "[GrafanaUnusedIndexQuery] request failed for #{table}/#{type}: #{e.message}"
        nil
      end

      def promql_for(table, type)
        <<~PROMQL.squish
          sum by (indexrelname) (
            increase(pg_stat_user_indexes_idx_scan{
              env="#{escape_label_value(@query_env)}",
              type="#{escape_label_value(type)}",
              relname="#{escape_label_value(table)}"
            }[#{LOOKBACK}])
          ) == 0
        PROMQL
      end

      # Escape backslash and double-quote to keep PromQL label values safe.
      def escape_label_value(value)
        value.to_s.gsub(/[\\"]/) { |c| "\\#{c}" }
      end

      def client
        @client ||= Grafana::Client.new(api_url: @api_url, token: @api_key)
      end
    end
  end
end
