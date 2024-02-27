# frozen_string_literal: true

module ServicePing
  module ServicePingSettings
    extend self

    def enabled_and_consented?
      enabled? && !User.single_user&.requires_usage_stats_consent?
    end

    def license_operational_metric_enabled?
      false
    end

    # If it is EE and license operational metric is true,
    # then we will show enable service ping checkbox checked,
    # as it will always send service ping
    def enabled?
      license_operational_metric_enabled? || ::Gitlab::CurrentSettings.usage_ping_enabled?
    end
  end
end

ServicePing::ServicePingSettings.extend_mod_with('ServicePing::ServicePingSettings')
