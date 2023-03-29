# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      module HealthStatus
        module Indicators
          class PatroniApdex
            include Gitlab::Utils::StrongMemoize

            def initialize(context)
              @context = context
            end

            def evaluate
              return Signals::NotAvailable.new(self.class, reason: 'indicator disabled') unless enabled?

              connection_error_message = fetch_connection_error_message
              return unknown_signal(connection_error_message) if connection_error_message.present?

              apdex_sli = fetch_sli(apdex_sli_query)
              return unknown_signal('Patroni service apdex can not be calculated') unless apdex_sli.present?

              if apdex_sli.to_f > apdex_slo.to_f
                Signals::Normal.new(self.class, reason: 'Patroni service apdex is above SLO')
              else
                Signals::Stop.new(self.class, reason: 'Patroni service apdex is below SLO')
              end
            end

            private

            attr_reader :context

            def enabled?
              Feature.enabled?(:batched_migrations_health_status_patroni_apdex, type: :ops)
            end

            def unknown_signal(reason)
              Signals::Unknown.new(self.class, reason: reason)
            end

            def fetch_connection_error_message
              return 'Patroni Apdex Settings not configured' unless database_apdex_settings.present?
              return 'Prometheus client is not ready' unless client.ready?
              return 'Apdex SLI query is not configured' unless apdex_sli_query
              return 'Apdex SLO is not configured' unless apdex_slo
            end

            def client
              @client ||= Gitlab::PrometheusClient.new(
                database_apdex_settings[:prometheus_api_url],
                allow_local_requests: true,
                verify: true
              )
            end

            def database_apdex_settings
              @database_apdex_settings ||= Gitlab::CurrentSettings.database_apdex_settings&.with_indifferent_access
            end

            def apdex_sli_query
              {
                gitlab_main: database_apdex_settings[:apdex_sli_query][:main],
                gitlab_ci: database_apdex_settings[:apdex_sli_query][:ci]
              }.fetch(context.gitlab_schema.to_sym)
            end
            strong_memoize_attr :apdex_sli_query

            def apdex_slo
              {
                gitlab_main: database_apdex_settings[:apdex_slo][:main],
                gitlab_ci: database_apdex_settings[:apdex_slo][:ci]
              }.fetch(context.gitlab_schema.to_sym)
            end
            strong_memoize_attr :apdex_slo

            def fetch_sli(query)
              response = client.query(query)
              metric = response&.first || {}
              value = metric.fetch('value', [])

              Array.wrap(value).second
            end
          end
        end
      end
    end
  end
end
