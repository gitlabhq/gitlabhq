# frozen_string_literal: true

databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

namespace :gitlab do
  namespace :background_migrations do
    desc 'Synchronously finish executing a batched background migration'
    task :finalize, [:job_class_name, :table_name, :column_name, :job_arguments] => :environment do |_, args|
      if Gitlab::Database.db_config_names.size > 1
        puts "Please specify the database".color(:red)
        exit 1
      end

      validate_finalization_arguments!(args)

      main_model = Gitlab::Database.database_base_models[:main]

      finalize_migration(
        args[:job_class_name],
        args[:table_name],
        args[:column_name],
        Gitlab::Json.parse(args[:job_arguments]),
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
            Gitlab::Json.parse(args[:job_arguments]),
            connection: model.connection
          )
        end
      end
    end

    desc 'Display the status of batched background migrations'
    task status: :environment do |_, args|
      Gitlab::Database.database_base_models.each do |name, model|
        display_migration_status(name, model.connection)
      end
    end

    namespace :status do
      ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
        next if name.to_s == 'geo'

        desc "Gitlab | DB | Display the status of batched background migrations on #{name} database"
        task name => :environment do |_, args|
          model = Gitlab::Database.database_base_models[name]
          display_migration_status(name, model.connection)
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

      puts "Done.".color(:green)
    end

    def display_migration_status(database_name, connection)
      Gitlab::Database::SharedModel.using_connection(connection) do
        statuses = Gitlab::Database::BackgroundMigration::BatchedMigration.statuses
        max_status_length = statuses.keys.map(&:length).max
        format_string = "%-#{max_status_length}s | %s\n"

        puts "Database: #{database_name}\n"

        Gitlab::Database::BackgroundMigration::BatchedMigration.find_each(batch_size: 100) do |migration|
          identification_fields = [
            migration.job_class_name,
            migration.table_name,
            migration.column_name,
            migration.job_arguments.to_json
          ].join(',')

          printf(format_string, migration.status, identification_fields)
        end
      end
    end

    def validate_finalization_arguments!(args)
      [:job_class_name, :table_name, :column_name, :job_arguments].each do |argument|
        unless args[argument]
          puts "Must specify #{argument} as an argument".color(:red)
          exit 1
        end
      end
    end
  end
end
