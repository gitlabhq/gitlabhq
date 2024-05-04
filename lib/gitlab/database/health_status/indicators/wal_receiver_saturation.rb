# frozen_string_literal: true

module Gitlab
  module Database
    module HealthStatus
      module Indicators
        class WalReceiverSaturation < PrometheusAlertIndicator
          private

          def enabled?
            Feature.enabled?(:db_health_check_wal_receiver_saturation, type: :ops)
          end

          def sli_query_key
            :wal_receiver_saturation_sli_query
          end

          def slo_key
            :wal_receiver_saturation_slo
          end

          def alert_condition
            ALERT_CONDITIONS[:below]
          end
        end
      end
    end
  end
end
