# frozen_string_literal: true

module ProductAnalytics
  class Settings
    CONFIG_KEYS = (%w[jitsu_host jitsu_project_xid jitsu_administrator_email jitsu_administrator_password] +
    %w[product_analytics_data_collector_host product_analytics_clickhouse_connection_string] +
    %w[cube_api_base_url cube_api_key]).freeze

    SNOWPLOW_CONFIG_KEYS = %w[product_analytics_configurator_connection_string].freeze

    ALL_CONFIG_KEYS = (ProductAnalytics::Settings::CONFIG_KEYS +
      ProductAnalytics::Settings::SNOWPLOW_CONFIG_KEYS).freeze

    def initialize(project:)
      @project = project
    end

    def enabled?
      ::Gitlab::CurrentSettings.product_analytics_enabled? && configured?
    end

    def configured?
      return unless configured_snowplow?

      CONFIG_KEYS.all? do |key|
        get_setting_value(key).present?
      end
    end

    def configured_snowplow?
      return true unless Feature.enabled?(:product_analytics_snowplow_support, @project)

      SNOWPLOW_CONFIG_KEYS.all? do |key|
        get_setting_value(key).present?
      end
    end

    ALL_CONFIG_KEYS.each do |key|
      define_method key.to_sym do
        get_setting_value(key)
      end
    end

    class << self
      def for_project(project)
        ProductAnalytics::Settings.new(project: project)
      end
    end

    private

    # rubocop:disable GitlabSecurity/PublicSend
    def get_setting_value(key)
      @project.project_setting.public_send(key).presence ||
        ::Gitlab::CurrentSettings.public_send(key)
    end
    # rubocop:enable GitlabSecurity/PublicSend
  end
end
