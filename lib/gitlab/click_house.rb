# frozen_string_literal: true

module Gitlab
  module ClickHouse
    DATABASES = [:main].freeze

    def self.configured?
      DATABASES.all? { |db| ::ClickHouse::Client.database_configured?(db) }
    end

    def self.enabled_for_analytics?(_group = nil)
      globally_enabled_for_analytics?
    end

    def self.globally_enabled_for_analytics?
      configured? && ::Gitlab::CurrentSettings.current_application_settings.use_clickhouse_for_analytics?
    end
  end
end
