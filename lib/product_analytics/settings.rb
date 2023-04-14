# frozen_string_literal: true

module ProductAnalytics
  class Settings
    CONFIG_KEYS = (%w[jitsu_host jitsu_project_xid jitsu_administrator_email jitsu_administrator_password] +
    %w[product_analytics_data_collector_host product_analytics_clickhouse_connection_string] +
    %w[cube_api_base_url cube_api_key]).freeze

    class << self
      def enabled?
        ::Gitlab::CurrentSettings.product_analytics_enabled? && configured?
      end

      def configured?
        CONFIG_KEYS.all? do |key|
          ::Gitlab::CurrentSettings.public_send(key)&.present? # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      CONFIG_KEYS.each do |key|
        define_method key.to_sym do
          ::Gitlab::CurrentSettings.public_send(key) # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end
