# frozen_string_literal: true

databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

namespace :gitlab do
  namespace :background_migrations do
    desc 'Synchronously finish executing a batched background migration'
    task :finalize, [:job_class_name, :table_name, :column_name, :job_arguments] => :environment do |_, args|
      if Gitlab::Database.db_config_names(with_schema: :gitlab_shared).size > 1
        puts Rainbow("Please specify the database").red
        exit 1
      end

      validate_finalization_arguments!(args)

      main_model = Gitlab::Database.database_base_models[:main]

      finalize_migration(
        args[:job_class_name],
        args[:table_name],
        args[:column_name],
        args[:job_arguments],
        connection: main_model.connection
      )
    end

    namespace :finalize do
      ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
        next if name.to_s == 'geo'

        desc "Gitlab | DB | Synchronously finish executing a batched background migration on #{name} database"
        task name, [:job_class_name, :table_name, :column_name, :job_arguments] => :environment do |_, args|
          validate_finalization_arguments!(args)

          model = Gitlab::Database.database_base_models[name]

          finalize_migration(
            args[:job_class_name],
            args[:table_name],
            args[:column_name],
            args[:job_arguments],
            connection: model.connection
          )
        end
      end
    end

    desc 'Display the status of batched background migrations'
    task status: :environment do |_, _args|
      Gitlab::Database.database_base_models.each do |database_name, model|
        next unless Gitlab::Database.has_database?(database_name)

        display_migration_status(database_name, model.connection)
      end
    end

    namespace :status do
      ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |database_name|
        next if database_name.to_s == 'geo'

        desc "Gitlab | DB | Display the status of batched background migrations on #{database_name} database"
        task database_name => :environment do |_, _args|
          model = Gitlab::Database.database_base_models[database_name]
          display_migration_status(database_name, model.connection)
        end
      end
    end

    desc 'Wait until all batched background migrations across every database have finished'
    task wait: :environment do |_, _args|
      # The loop runs until every database is clear. It has no internal timeout by design:
      # the caller is expected to bound the total run time, and to retry the whole task on
      # transient database errors, which are left to propagate rather than be swallowed here.
      interval = wait_interval_seconds

      puts "Waiting for batched background migrations to finish, checking every #{interval}s..."

      loop do
        by_database = unfinished_batched_background_migrations_by_database

        failed = failed_migrations(by_database)

        if failed.any?
          puts Rainbow('Some batched background migrations are in a failed state and must be finalized manually:').red
          print_migrations(failed)
          exit 1
        end

        remaining = by_database.values.sum(&:size)

        if remaining == 0
          puts Rainbow('All batched background migrations have finished.').green
          break
        end

        puts "Still waiting on #{remaining} batched background migration(s):"
        print_migrations(by_database)

        Kernel.sleep(interval)
      end
    end

    private

    def wait_interval_seconds
      raw = ENV.fetch('BATCHED_MIGRATIONS_WAIT_INTERVAL_SECONDS', '30')
      # Parse in base 10 explicitly: the value is a plain decimal supplied by an external
      # orchestrator, and Integer's default base would read a zero-padded value like "030" as octal.
      interval = Integer(raw, 10, exception: false)

      if interval.nil? || interval < 1
        puts Rainbow("BATCHED_MIGRATIONS_WAIT_INTERVAL_SECONDS must be a positive integer, got #{raw.inspect}").red
        exit 1
      end

      interval
    end

    def unfinished_batched_background_migrations_by_database
      Gitlab::Database.database_base_models.each_with_object({}) do |(database_name, model), result|
        next unless Gitlab::Database.has_database?(database_name)

        Gitlab::Database::SharedModel.using_connection(model.connection) do
          result[database_name] = Gitlab::Database::BackgroundMigration::BatchedMigration.unfinished.to_a
        end
      end
    end

    def failed_migrations(migrations_by_database)
      migrations_by_database.each_with_object({}) do |(database_name, migrations), result|
        failed = migrations.select(&:failed?)
        result[database_name] = failed if failed.any?
      end
    end

    def print_migrations(migrations_by_database)
      migrations_by_database.each do |database_name, migrations|
        next if migrations.empty?

        puts "Database: #{database_name}"

        migrations.each do |migration|
          puts "  #{migration.status_name} | #{migration_identifier(migration)}"
        end
      end
    end

    def finalize_migration(class_name, table_name, column_name, job_arguments, connection:)
      Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.finalize(
        class_name,
        table_name,
        column_name,
        Gitlab::Json.parse(job_arguments),
        connection: connection
      )

      puts Rainbow("Done.").green
    end

    def display_migration_status(database_name, connection)
      Gitlab::Database::SharedModel.using_connection(connection) do
        valid_status = Gitlab::Database::BackgroundMigration::BatchedMigration.valid_status
        max_status_length = valid_status.map(&:length).max
        format_string = "%-#{max_status_length}s | %s\n"

        puts "Database: #{database_name}\n"

        Gitlab::Database::BackgroundMigration::BatchedMigration.find_each(batch_size: 100) do |migration|
          printf(format_string, migration.status_name, migration_identifier(migration))
        end
      end
    end

    def migration_identifier(migration)
      [
        migration.job_class_name,
        migration.table_name,
        migration.column_name,
        migration.job_arguments.to_json
      ].join(',')
    end

    def validate_finalization_arguments!(args)
      [:job_class_name, :table_name, :column_name, :job_arguments].each do |argument|
        unless args[argument]
          puts Rainbow("Must specify #{argument} as an argument").red
          exit 1
        end
      end
    end
  end
end
