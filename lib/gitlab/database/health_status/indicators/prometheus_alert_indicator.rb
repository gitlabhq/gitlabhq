# frozen_string_literal: true

module Gitlab
  module Database
    module HealthStatus
      module Indicators
        class PrometheusAlertIndicator
          include Gitlab::Utils::StrongMemoize

          ALERT_CONDITIONS = {
            above: :above,
            below: :below
          }.freeze

          def initialize(context)
            @connection = context.connection
          end

          def evaluate
            return Signals::NotAvailable.new(self.class, reason: 'indicator disabled') unless enabled?

            connection_error_message = fetch_connection_error_message
            return unknown_signal(connection_error_message) if connection_error_message.present?

            sli = fetch_sli(sli_query)
            return unknown_signal("#{indicator_name} can not be calculated") unless sli.present?

            if alert_condition == ALERT_CONDITIONS[:above] ? sli.to_f > slo.to_f : sli.to_f < slo.to_f
              Signals::Normal.new(self.class, reason: "#{indicator_name} SLI condition met")
            else
              Signals::Stop.new(self.class, reason: "#{indicator_name} SLI condition not met")
            end
          end

          private

          attr_reader :connection

          def indicator_name
            self.class.name.demodulize
          end

          # By default SLIs are expected to be above SLOs, but there can be cases
          # where we want it to be below SLO (eg: WAL rate). For such indicators
          # the sub-class should override this default alert_condition.
          def alert_condition
            ALERT_CONDITIONS[:above]
          end

          def enabled?
            raise NotImplementedError, "prometheus alert based indicators must implement #{__method__}"
          end

          def slo_key
            raise NotImplementedError, "prometheus alert based indicators must implement #{__method__}"
          end

          def sli_key
            raise NotImplementedError, "prometheus alert based indicators must implement #{__method__}"
          end

          def fetch_connection_error_message
            return 'Prometheus Settings not configured' unless prometheus_alert_db_indicators_settings.present?
            return 'Prometheus client is not ready' unless client.ready?
            return "#{indicator_name} SLI query is not configured" unless sli_query
            return "#{indicator_name} SLO is not configured" unless slo
          end

          def prometheus_alert_db_indicators_settings
            @prometheus_alert_db_indicators_settings ||= Gitlab::CurrentSettings
              .prometheus_alert_db_indicators_settings&.with_indifferent_access
          end

          def client
            return mimir_client if Feature.enabled?(:db_health_check_using_mimir_client, type: :ops)

            prometheus_client
          end

          def prometheus_client
            @prometheus_client ||= Gitlab::PrometheusClient.new(
              prometheus_alert_db_indicators_settings[:prometheus_api_url],
              allow_local_requests: true,
              verify: true
            )
          end

          def mimir_client
            @mimir_client ||= Gitlab::MimirClient.new(
              mimir_url: prometheus_alert_db_indicators_settings[:mimir_api_url],
              user: ENV['GITLAB_MIMIR_AUTH_USER'],
              password: ENV['GITLAB_MIMIR_AUTH_PASSWORD'],
              options: {
                allow_local_requests: true,
                verify: true
              }
            )
          end

          def sli_query
            # TODO: temporary until CRs can be rolled out with https://gitlab.com/gitlab-org/gitlab/-/issues/501105
            gitlab_sec_query = prometheus_alert_db_indicators_settings[sli_query_key][:sec] ||
              prometheus_alert_db_indicators_settings[sli_query_key][:main]

            {
              gitlab_main: prometheus_alert_db_indicators_settings[sli_query_key][:main],
              gitlab_main_cell: prometheus_alert_db_indicators_settings[sli_query_key][:main_cell],
              gitlab_ci: prometheus_alert_db_indicators_settings[sli_query_key][:ci],
              gitlab_sec: gitlab_sec_query
            }.fetch(:"gitlab_#{connection.load_balancer.name}", nil)
          end
          strong_memoize_attr :sli_query

          def slo
            # TODO: temporary until CRs can be rolled out with https://gitlab.com/gitlab-org/gitlab/-/issues/501105
            gitlab_sec_query = prometheus_alert_db_indicators_settings[slo_key][:sec] ||
              prometheus_alert_db_indicators_settings[slo_key][:main]

            {
              gitlab_main: prometheus_alert_db_indicators_settings[slo_key][:main],
              gitlab_main_cell: prometheus_alert_db_indicators_settings[slo_key][:main_cell],
              gitlab_ci: prometheus_alert_db_indicators_settings[slo_key][:ci],
              gitlab_sec: gitlab_sec_query
            }.fetch(:"gitlab_#{connection.load_balancer.name}", nil)
          end
          strong_memoize_attr :slo

          def fetch_sli(query)
            response = client.query(query)
            metric = response&.first || {}
            value = metric.fetch('value', [])

            Array.wrap(value).second
          end

          def unknown_signal(reason)
            Signals::Unknown.new(self.class, reason: reason)
          end
        end
      end
    end
  end
end
