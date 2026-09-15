# frozen_string_literal: true

module Gitlab
  module ClickHouse
    DATABASES = [:main].freeze
    SIPHON_INTERNAL_EVENTS_TABLE = 'siphon_internal_events'
    SIPHON_CACHE_KEY_PREFIX = 'clickhouse:siphon_enabled'

    def self.configured?
      DATABASES.all? { |db| ::ClickHouse::Client.database_configured?(db) }
    end

    def self.enabled_for_analytics?(_group = nil)
      globally_enabled_for_analytics?
    end

    def self.globally_enabled_for_analytics?
      configured? && ::Gitlab::CurrentSettings.current_application_settings.use_clickhouse_for_analytics?
    end

    # Whether Siphon has replicated anything into ClickHouse: globally when
    # +table_name+ is nil, or for that PostgreSQL table specifically.
    #
    # Only positive results are cached, and only for the life of the process: a table can
    # start replicating after a negative check, but one that has replicated is not expected
    # to stop.
    #
    # @param table_name [String, Symbol, nil] PostgreSQL table name, as in db/siphon/tables/<table>.yml
    # @return [Boolean]
    def self.siphon_enabled?(table_name = nil)
      return false unless configured?
      return true if siphon_cache.read(siphon_cache_key(table_name))

      siphon_replicating?(table_name).tap do |enabled|
        cache_siphon_enabled(table_name) if enabled
      end
    end

    def self.siphon_replicating?(table_name)
      query = ::ClickHouse::Client::QueryBuilder.new(SIPHON_INTERNAL_EVENTS_TABLE).select(:postgresql_table)
      # rubocop: disable CodeReuse/ActiveRecord -- this is a ClickHouse query builder, not an AR relation
      query = query.where(postgresql_schema: 'public', postgresql_table: table_name.to_s) if table_name
      # rubocop: enable CodeReuse/ActiveRecord

      ::ClickHouse::Client.select(query.limit(1), :main).any?
    rescue ::ClickHouse::Client::Error, *Gitlab::HTTP::HTTP_ERRORS => e
      ::Gitlab::ErrorTracking.log_exception(e)
      false
    end
    private_class_method :siphon_replicating?

    # A positive per-table result also proves Siphon is enabled globally, so it primes the
    # global key and lets the global check skip its own ClickHouse query.
    def self.cache_siphon_enabled(table_name)
      siphon_cache.write(siphon_cache_key(nil), true)
      siphon_cache.write(siphon_cache_key(table_name), true) if table_name
    end
    private_class_method :cache_siphon_enabled

    def self.siphon_cache_key(table_name)
      table_name ? "#{SIPHON_CACHE_KEY_PREFIX}:#{table_name}" : SIPHON_CACHE_KEY_PREFIX
    end
    private_class_method :siphon_cache_key

    def self.siphon_cache
      ::Gitlab::ProcessMemoryCache.cache_backend
    end
    private_class_method :siphon_cache
  end
end
