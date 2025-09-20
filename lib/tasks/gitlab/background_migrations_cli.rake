# frozen_string_literal: true

databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

namespace :gitlab do
  namespace :background_migrations do
    desc 'GitLab | DB | List all background migrations'
    task list: :environment do
      include Gitlab::Database::BackgroundMigration::RakeTask

      migrations = []
      ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |database_name|
        next if database_name.to_s == 'geo'

        model = Gitlab::Database.database_base_models[database_name]
        connection = model.connection

        attributes = %w[id table_name job_class_name status]
        Gitlab::Database::SharedModel.using_connection(connection) do
          Gitlab::Database::BackgroundMigration::BatchedMigration
            .for_gitlab_schema(Gitlab::Database.gitlab_schemas_for_connection(connection))
            .order(:id)
            .each do |migration|
              migrations << migration.slice(attributes)
                .merge(
                  'id' => "#{database_name}_#{migration.id}",
                  'status' => migration.status_name
                )
                .values
            end
        end
      end

      print_table([%w[id table_name job_class_name status]] + migrations)
    end

    desc 'GitLab | DB | Show background migration details'
    task :show, [:migration_id] => :environment do |_, args|
      include Gitlab::Database::BackgroundMigration::RakeTask

      migration_id = args[:migration_id]
      connection, id = connection_and_id_from_params(migration_id)

      Gitlab::Database::SharedModel.using_connection(connection) do
        migration = Gitlab::Database::BackgroundMigration::BatchedMigration
          .for_gitlab_schema(Gitlab::Database.gitlab_schemas_for_connection(connection))
          .find(id)

        attributes = migration.attributes
          .merge(
            'id' => migration_id,
            'status' => migration.status_name
          )

        print_table(attributes, headers: false)
      end
    end

    desc 'GitLab | DB | Pause active background migration'
    task :pause, [:migration_id] => :environment do |_, args|
      include Gitlab::Database::BackgroundMigration::RakeTask

      migration_id = args[:migration_id]
      connection, id = connection_and_id_from_params(migration_id)

      Gitlab::Database::SharedModel.using_connection(connection) do
        migration = Gitlab::Database::BackgroundMigration::BatchedMigration
          .for_gitlab_schema(Gitlab::Database.gitlab_schemas_for_connection(connection))
          .find(id)

        print_error('You can pause only `active` batched background migrations.') unless migration.active?

        migration.pause!
        print_message("Done.")
      end
    end

    desc 'GitLab | DB | Resume paused background migration'
    task :resume, [:migration_id] => :environment do |_, args|
      include Gitlab::Database::BackgroundMigration::RakeTask

      migration_id = args[:migration_id]
      connection, id = connection_and_id_from_params(migration_id)

      Gitlab::Database::SharedModel.using_connection(connection) do
        migration = Gitlab::Database::BackgroundMigration::BatchedMigration
          .for_gitlab_schema(Gitlab::Database.gitlab_schemas_for_connection(connection))
          .find(id)

        print_error('You can resume only `paused` batched background migrations.') unless migration.paused?

        migration.execute!
        print_message("Done.")
      end
    end
  end
end
