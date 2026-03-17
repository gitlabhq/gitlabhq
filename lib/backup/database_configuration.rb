# frozen_string_literal: true

module Backup
  class DatabaseConfiguration
    # Connection name is the key used in `config/database.yml` for multi-database connection configuration
    #
    # @return [String]
    attr_reader :connection_name

    # Initializes configuration
    #
    # @param [String] connection_name the key from `database.yml` for multi-database connection configuration
    # @param [Hash] custom_config optional custom database configuration hash (bypasses database.yml lookup)
    #   Example: {
    #   host: 'localhost', port: 5432, database: 'my_db', username: 'user', password: 'pass', adapter: 'postgresql'
    #   }
    def initialize(connection_name, custom_config: nil)
      @connection_name = connection_name
      @custom_config = custom_config

      @activerecord_database_config =
        if custom_config
          # Use custom configuration instead of looking up in database.yml
          build_custom_database_config(connection_name, custom_config)
        else
          @activerecord_database_config = ActiveRecord::Base.configurations.find_db_config(connection_name) ||
            ActiveRecord::Base.configurations.find_db_config('main')
        end
    end

    # ENV variables that can override each database configuration
    # These are used along with OVERRIDE_PREFIX and database name
    # @see #process_config_overrides!
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

    # Prefixes used for ENV variables overriding database configuration
    OVERRIDE_PREFIXES = %w[GITLAB_BACKUP_ GITLAB_OVERRIDE_].freeze

    # Return the HashConfig for the database
    #
    # @return [ActiveRecord::DatabaseConfigurations::HashConfig]
    def activerecord_configuration
      ActiveRecord::DatabaseConfigurations::HashConfig.new(
        @activerecord_database_config.env_name,
        connection_name,
        activerecord_variables
      )
    end

    # Return postgres ENV variable values for current database with overrided values
    #
    # @return[Hash<String,String>] hash of postgres ENV variables
    def pg_env_variables
      process_config_overrides! unless @pg_env_variables

      @pg_env_variables
    end

    # Return activerecord configuration values for current database with overrided values
    #
    # @return[Hash<String,String>] activerecord database.yml configuration compatible values
    def activerecord_variables
      process_config_overrides! unless @activerecord_variables

      @activerecord_variables
    end

    private

    # Build a custom ActiveRecord database configuration from a hash
    #
    # @param [String] connection_name the connection name
    # @param [Hash] config the database configuration hash
    # @return [ActiveRecord::DatabaseConfigurations::HashConfig]
    def build_custom_database_config(connection_name, config)
      # Ensure required keys are present
      required_keys = [:adapter, :database]
      missing_keys = required_keys - config.keys
      raise ArgumentError, "Custom config missing required keys: #{missing_keys.join(', ')}" unless missing_keys.empty?

      # Set defaults for optional keys
      config_with_defaults = {
        host: 'localhost',
        port: 5432,
        pool: 5,
        encoding: 'unicode'
      }.merge(config)

      # Create a HashConfig object
      ActiveRecord::DatabaseConfigurations::HashConfig.new(
        Rails.env,
        connection_name,
        config_with_defaults
      )
    end

    def process_config_overrides!
      @activerecord_variables = original_activerecord_config
      @pg_env_variables = {}

      SUPPORTED_OVERRIDES.each do |config_key, env_variable_name|
        # This enables the use of different PostgreSQL settings in
        # case PgBouncer is used. PgBouncer clears the search path,
        # which wreaks havoc on Rails if connections are reused.

        # Skip ENV override processing for custom configs unless explicitly needed
        if @custom_config
          val = @activerecord_variables[config_key].to_s.presence
          @pg_env_variables[env_variable_name] = val if val
        else
          OVERRIDE_PREFIXES.each do |override_prefix|
            override_all = "#{override_prefix}#{env_variable_name}"
            override_db = "#{override_prefix}#{connection_name.upcase}_#{env_variable_name}"
            val = ENV[override_db].presence ||
              ENV[override_all].presence ||
              @activerecord_variables[config_key].to_s.presence

            next unless val

            @pg_env_variables[env_variable_name] = val
            @activerecord_variables[config_key] = val
          end
        end
      end
    end

    # Return the database configuration from rails config/database.yml file
    # in the format expected by ActiveRecord::DatabaseConfigurations::HashConfig
    #
    # @return [Hash] configuration hash
    def original_activerecord_config
      @activerecord_database_config.configuration_hash.dup
    end
  end
end
