# frozen_string_literal: true

module Gitlab
  module Database
    module HealthStatus
      module Indicators
        class PatroniApdex < PrometheusAlertIndicator
          private

          def enabled?
            Feature.enabled?(:batched_migrations_health_status_patroni_apdex, type: :ops)
          end

          def sli_query_key
            :apdex_sli_query
          end

          def slo_key
            :apdex_slo
          end
        end
      end
    end
  end
end
