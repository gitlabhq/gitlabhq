# frozen_string_literal: true

module ServicePing
  class BuildPayloadService
    def execute
      return {} unless allowed_to_report?

      raw_payload
    end

    private

    def allowed_to_report?
      product_intelligence_enabled? && !User.single_user&.requires_usage_stats_consent?
    end

    def product_intelligence_enabled?
      ::Gitlab::CurrentSettings.usage_ping_enabled?
    end

    def raw_payload
      @raw_payload ||= ::Gitlab::UsageData.data(force_refresh: true)
    end
  end
end

ServicePing::BuildPayloadService.prepend_mod_with('ServicePing::BuildPayloadService')
