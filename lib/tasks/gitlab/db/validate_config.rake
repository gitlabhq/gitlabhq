# frozen_string_literal: true

databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

namespace :gitlab do
  namespace :db do
    DB_CONFIG_NAME_KEY = 'gitlab_db_config_name'

    DB_IDENTIFIER_SQL = <<-SQL
      SELECT system_identifier, current_database()
      FROM pg_control_system()
    SQL

    # We fetch timestamp as a way to properly handle race conditions
    # fail in such cases, which should not really happen in production environment
    DB_IDENTIFIER_WITH_DB_CONFIG_NAME_SQL = <<-SQL
      SELECT
        system_identifier, current_database(),
        value as db_config_name, created_at as timestamp
      FROM pg_control_system()
      LEFT JOIN ar_internal_metadata ON ar_internal_metadata.key=$1
    SQL

    desc 'Validates `config/database.yml` to ensure a correct behavior is configured'
    task validate_config: :environment do
      original_db_config = ActiveRecord::Base.connection_db_config # rubocop:disable Database/MultipleDatabases

      db_configs = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, include_hidden: true)
      db_configs = db_configs.reject(&:replica?)

      # The `pg_control_system()` is not enough to properly discover matching database systems
      # since in case of cluster promotion it will return the same identifier as main cluster
      # We instead set an `ar_internal_metadata` information with configured database name
      db_configs.reverse_each do |db_config|
        insert_db_identifier(db_config)
      end

      # Map each database connection into unique identifier of system+database
      all_connections = db_configs.map do |db_config|
        {
          name: db_config.name,
          config: db_config,
          database_tasks?: db_config.database_tasks?,
          identifier: get_db_identifier(db_config)
        }
      end

      unique_connections = all_connections.group_by { |connection| connection[:identifier] }
      primary_connection = all_connections.find { |connection| ActiveRecord::Base.configurations.primary?(connection[:name]) }
      named_connections = all_connections.index_by { |connection| connection[:name] }

      warnings = []

      # The `main:` should always have `database_tasks: true`
      unless primary_connection[:database_tasks?]
        warnings << "- The '#{primary_connection[:name]}' is required to use 'database_tasks: true'"
      end

      # Each unique database should have exactly one configuration with `database_tasks: true`
      unique_connections.each do |identifier, connections|
        next unless identifier

        connections_with_tasks = connections.select { |connection| connection[:database_tasks?] }
        next unless connections_with_tasks.many?

        names = connections_with_tasks.pluck(:name)

        warnings << "- Many configurations (#{names.join(', ')}) " \
          "share the same database (#{identifier}). " \
          "This will result in failures provisioning or migrating this database. " \
          "Ensure that additional databases are configured " \
          "with 'database_tasks: false' or are pointing to a dedicated database host."
      end

      # Each configuration with `database_tasks: false` should share the database with `main:`
      all_connections.each do |connection|
        share_with = Gitlab::Database.db_config_share_with(connection[:config])
        next unless share_with

        shared_connection = named_connections[share_with]
        unless shared_connection
          warnings << "- The '#{connection[:name]}' is expecting to share configuration with '#{share_with}', " \
            "but no such is to be found."
          next
        end

        # Skip if databases are yet to be provisioned
        next unless connection[:identifier] && shared_connection[:identifier]

        connection_identifier, shared_connection_identifier = [
          connection[:identifier], shared_connection[:identifier]
        ].map { |identifier| identifier.slice("system_identifier", "current_database") }

        unless connection_identifier == shared_connection_identifier
          warnings << "- The '#{connection[:name]}' since it is using 'database_tasks: false' " \
            "should share database with '#{share_with}:'."
        end
      end

      if warnings.any?
        warnings.unshift("Database config validation failure:")

        # Warn (for now) by default in production environment
        if Gitlab::Utils.to_boolean(ENV['GITLAB_VALIDATE_DATABASE_CONFIG'], default: true)
          warnings << "Use `export GITLAB_VALIDATE_DATABASE_CONFIG=0` to ignore this validation."

          raise warnings.join("\n")
        else
          warnings << "Use `export GITLAB_VALIDATE_DATABASE_CONFIG=1` to enforce this validation."

          warn warnings.join("\n")
        end
      end

    ensure
      ActiveRecord::Base.establish_connection(original_db_config) # rubocop: disable Database/EstablishConnection
    end

    Rake::Task['db:migrate'].enhance(['gitlab:db:validate_config'])
    Rake::Task['db:schema:load'].enhance(['gitlab:db:validate_config'])
    Rake::Task['db:schema:dump'].enhance(['gitlab:db:validate_config'])

    ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
      Rake::Task["db:migrate:#{name}"].enhance(['gitlab:db:validate_config'])
      Rake::Task["db:schema:load:#{name}"].enhance(['gitlab:db:validate_config'])
      Rake::Task["db:schema:dump:#{name}"].enhance(['gitlab:db:validate_config'])
    end

    def insert_db_identifier(db_config)
      ActiveRecord::Base.establish_connection(db_config) # rubocop: disable Database/EstablishConnection

      if ::Gitlab.next_rails?
        internal_metadata = ActiveRecord::Base.connection.internal_metadata # rubocop: disable Database/MultipleDatabases
        internal_metadata[DB_CONFIG_NAME_KEY] = db_config.name if internal_metadata.table_exists?
      elsif ActiveRecord::InternalMetadata.table_exists?
        ts = Time.zone.now

        ActiveRecord::InternalMetadata.upsert(
          { key: DB_CONFIG_NAME_KEY,
            value: db_config.name,
            created_at: ts,
            updated_at: ts }
        )
      end
    rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => err
      warn "WARNING: Could not establish database connection for #{db_config.name}: #{err.message}"
    rescue ActiveRecord::NoDatabaseError
    rescue ActiveRecord::StatementInvalid => err
      raise unless err.cause.is_a?(PG::ReadOnlySqlTransaction)

      warn "WARNING: Could not write to the database #{db_config.name}: cannot execute UPSERT in a read-only transaction"
    end

    def get_db_identifier(db_config)
      ActiveRecord::Base.establish_connection(db_config) # rubocop: disable Database/EstablishConnection

      internal_metadata =
        if ::Gitlab.next_rails?
          ActiveRecord::Base.connection.internal_metadata # rubocop: disable Database/MultipleDatabases
        else
          ActiveRecord::InternalMetadata
        end

      # rubocop:disable Database/MultipleDatabases
      if internal_metadata.table_exists?
        ActiveRecord::Base.connection.select_one(
          DB_IDENTIFIER_WITH_DB_CONFIG_NAME_SQL, nil, [DB_CONFIG_NAME_KEY])
      else
        ActiveRecord::Base.connection.select_one(DB_IDENTIFIER_SQL)
      end
      # rubocop:enable Database/MultipleDatabases
    rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => err
      warn "WARNING: Could not establish database connection for #{db_config.name}: #{err.message}"
    rescue ActiveRecord::NoDatabaseError
    end
  end
end
