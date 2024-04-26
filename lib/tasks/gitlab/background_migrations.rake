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

    private

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
          identification_fields = [
            migration.job_class_name,
            migration.table_name,
            migration.column_name,
            migration.job_arguments.to_json
          ].join(',')

          printf(format_string, migration.status_name, identification_fields)
        end
      end
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
