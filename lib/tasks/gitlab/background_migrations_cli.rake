# frozen_string_literal: true

databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml
  .fetch(Rails.env, {}).keys

namespace :gitlab do
  namespace :background_migrations do
    desc 'GitLab | DB | List all background migrations'
    task list: :environment do
      include Gitlab::Database::BackgroundMigration::RakeTask

      migrations = []
      databases.each do |database_name|
        next if database_name.to_s == 'geo'

        model = Gitlab::Database.database_base_models[database_name]
        connection = model.connection

        attributes = %w[id table_name job_class_name status]
        Gitlab::Database::SharedModel.using_connection(connection) do
          Gitlab::Database::BackgroundMigration::BatchedMigration
            .for_gitlab_schema(Gitlab::Database.gitlab_schemas_for_connection(connection))
            .queue_order
            .each do |migration|
              progress = if migration.progress.present?
                           ActiveSupport::NumberHelper.number_to_percentage(migration.progress, precision: 2)
                         end

              if progress.present? && migration.estimated_time_remaining.present?
                progress = "#{progress} (estimated time remaining: #{migration.estimated_time_remaining})"
              end

              migrations << migration.slice(attributes)
                .merge(
                  'id' => "#{database_name}_#{migration.id}",
                  'status' => migration.status_name,
                  'progress' => progress
                )
                .values
            end
        end
      end

      print_table([%w[id table_name job_class_name status progress]] + migrations)
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

        print_error('You can pause only `active` background migrations.') unless migration.active?

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

        print_error('You can resume only `paused` background migrations.') unless migration.paused?

        migration.execute!
        print_message("Done.")
      end
    end

    desc 'GitLab | DB | Execute background migration'
    task :execute, [:migration_id] => :environment do |_, args|
      include Gitlab::Database::BackgroundMigration::RakeTask

      migration_id = args[:migration_id]
      connection, id = connection_and_id_from_params(migration_id)

      Gitlab::Database::SharedModel.using_connection(connection) do
        migration = Gitlab::Database::BackgroundMigration::BatchedMigration
          .for_gitlab_schema(Gitlab::Database.gitlab_schemas_for_connection(connection))
          .find(id)

        prompt = TTY::Prompt.new
        unless prompt.yes?(Rainbow('Are you sure you want to execute this migration?').red, default: false)
          print_message("Bye.", force_exit: true)
        end

        print_message("Executing background migration `#{args[:migration_id]}`...")

        Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.execute_migration(
          migration,
          connection: connection,
          force: true
        )

        if migration.finished?
          print_message("Done.")
        else
          print_error(
            "Background migration #{args[:migration_id]} could not be completed. " \
              "Check with `gitlab:background_migrations:show[#{args[:migration_id]}]` for more details."
          )
        end
      end
    end

    desc 'GitLab | DB | Execute all background migrations'
    task :execute_all, [:migration_id] => :environment do
      include Gitlab::Database::BackgroundMigration::RakeTask

      prompt = TTY::Prompt.new
      unless prompt.yes?(Rainbow('Are you sure you want to execute all unfinished migrations?').red, default: false)
        print_message("Bye.", force_exit: true)
      end

      databases.each do |database_name|
        next if database_name.to_s == 'geo'

        model = Gitlab::Database.database_base_models[database_name]
        connection = model.connection

        Gitlab::Database::SharedModel.using_connection(connection) do
          migrations = Gitlab::Database::BackgroundMigration::BatchedMigration
            .for_gitlab_schema(Gitlab::Database.gitlab_schemas_for_connection(connection))
            .unfinished
            .queue_order

          if migrations.any?
            print_message("[#{database_name}] Executing #{migrations.count} background migrations...")
          else
            print_message("[#{database_name}] No migrations to execute.")
            next
          end

          migrations.each do |migration|
            print_message("[#{database_name}_#{migration.id}]: Start.")

            begin
              Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.execute_migration(
                migration,
                connection: connection,
                force: true
              )

              if migration.finished?
                print_message("[#{database_name}_#{migration.id}]: Done.")
              else
                print_error("[#{database_name}_#{migration.id}]: Failed.", force_exit: false)
              end
            rescue StandardError => e
              print_error("[#{database_name}_#{migration.id}]: Failed: '#{e.message}'.", force_exit: false)
            end
          end
        end
      end
    end
  end
end
