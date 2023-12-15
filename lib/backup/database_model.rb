# frozen_string_literal: true

module Backup
  class DatabaseModel
    SUPPORTED_OVERRIDES = {
      username: 'PGUSER',
      host: 'PGHOST',
      port: 'PGPORT',
      password: 'PGPASSWORD',
      # SSL
      sslmode: 'PGSSLMODE',
      sslkey: 'PGSSLKEY',
      sslcert: 'PGSSLCERT',
      sslrootcert: 'PGSSLROOTCERT',
      sslcrl: 'PGSSLCRL',
      sslcompression: 'PGSSLCOMPRESSION'
    }.freeze

    OVERRIDE_PREFIXES = %w[GITLAB_BACKUP_ GITLAB_OVERRIDE_].freeze

    attr_reader :config

    def initialize(name)
      configure_model(name)
    end

    def connection
      @model.connection
    end

    private

    def configure_model(name)
      source_model = Gitlab::Database.database_base_models_with_gitlab_shared[name] ||
        Gitlab::Database.database_base_models_with_gitlab_shared['main']

      @model = backup_model_for(name)

      original_config = source_model.connection_db_config.configuration_hash.dup

      @config = config_for_backup(name, original_config)

      @model.establish_connection(
        ActiveRecord::DatabaseConfigurations::HashConfig.new(
          source_model.connection_db_config.env_name,
          name.to_s,
          original_config.merge(@config[:activerecord])
        )
      )

      Gitlab::Database::LoadBalancing::Setup.new(@model).setup
    end

    def backup_model_for(name)
      klass_name = name.camelize

      return "#{self.class.name}::#{klass_name}".constantize if self.class.const_defined?(klass_name.to_sym, false)

      self.class.const_set(klass_name, Class.new(ApplicationRecord))
    end

    def config_for_backup(name, config)
      db_config = {
        activerecord: config,
        pg_env: {}
      }
      SUPPORTED_OVERRIDES.each do |opt, arg|
        # This enables the use of different PostgreSQL settings in
        # case PgBouncer is used. PgBouncer clears the search path,
        # which wreaks havoc on Rails if connections are reused.
        OVERRIDE_PREFIXES.each do |override_prefix|
          override_all = "#{override_prefix}#{arg}"
          override_db = "#{override_prefix}#{name.upcase}_#{arg}"
          val = ENV[override_db].presence || ENV[override_all].presence || config[opt].to_s.presence

          next unless val

          db_config[:pg_env][arg] = val
          db_config[:activerecord][opt] = val
        end
      end

      db_config
    end
  end
end
