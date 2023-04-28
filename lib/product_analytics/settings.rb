# frozen_string_literal: true

module ProductAnalytics
  class Settings
    CONFIG_KEYS = (%w[jitsu_host jitsu_project_xid jitsu_administrator_email jitsu_administrator_password] +
    %w[product_analytics_data_collector_host product_analytics_clickhouse_connection_string] +
    %w[cube_api_base_url cube_api_key]).freeze

    def initialize(project:)
      @project = project
    end

    def enabled?
      ::Gitlab::CurrentSettings.product_analytics_enabled? && configured?
    end

    # rubocop:disable GitlabSecurity/PublicSend
    def configured?
      CONFIG_KEYS.all? do |key|
        @project.project_setting.public_send(key).present? ||
          ::Gitlab::CurrentSettings.public_send(key).present?
      end
    end

    CONFIG_KEYS.each do |key|
      define_method key.to_sym do
        @project.project_setting.public_send(key).presence || ::Gitlab::CurrentSettings.public_send(key)
      end
    end
    # rubocop:enable GitlabSecurity/PublicSend

    class << self
      def for_project(project)
        ProductAnalytics::Settings.new(project: project)
      end
    end
  end
end
