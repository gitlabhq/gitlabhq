# frozen_string_literal: true

module Gitlab
  module ClickHouse
    DATABASES = [:main].freeze

    def self.configured?
      DATABASES.all? { |db| ::ClickHouse::Client.database_configured?(db) }
    end
  end
end

Gitlab::ClickHouse.prepend_mod_with('Gitlab::ClickHouse')
