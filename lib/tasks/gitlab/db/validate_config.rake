# frozen_string_literal: true

databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

namespace :gitlab do
  namespace :db do
    desc 'Validates `config/database.yml` to ensure a correct behavior is configured'
    task validate_config: :environment do
      original_db_config = ActiveRecord::Base.connection_db_config

      # The include_replicas: is a legacy name to fetch all hidden entries (replica: true or database_tasks: false)
      # Once we upgrade to Rails 7.x this should be changed to `include_hidden: true`
      # Ref.: https://github.com/rails/rails/blob/f2d9316ba965e150ad04596085ee10eea4f58d3e/activerecord/lib/active_record/database_configurations.rb#L48
      db_configs = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, include_replicas: true)
      db_configs = db_configs.reject(&:replica?)

      # Map each database connection into unique identifier of system+database
      all_connections = db_configs.map do |db_config|
        identifier =
          begin
            ActiveRecord::Base.establish_connection(db_config) # rubocop: disable Database/EstablishConnection
            ActiveRecord::Base.connection.select_one("SELECT system_identifier, current_database() FROM pg_control_system()")
          rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => err
            warn "WARNING: Could not establish database connection for #{db_config.name}: #{err.message}"
          rescue ActiveRecord::NoDatabaseError
          end

        {
          name: db_config.name,
          config: db_config,
          database_tasks?: db_config.database_tasks?,
          identifier: identifier
        }
      end.compact

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
        if connections_with_tasks.many?
          names = connections_with_tasks.pluck(:name)

          warnings << "- Many configurations (#{names.join(', ')}) " \
            "share the same database (#{identifier}). " \
            "This will result in failures provisioning or migrating this database. " \
            "Ensure that additional databases are configured " \
            "with 'database_tasks: false' or are pointing to a dedicated database host."
        end
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

        unless connection[:identifier] == shared_connection[:identifier]
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
  end
end
