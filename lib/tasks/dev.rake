# frozen_string_literal: true

task dev: ["dev:setup"]

namespace :dev do
  desc "GitLab | Dev | Setup developer environment (db, fixtures)"
  task setup: :environment do
    ENV['force'] = 'yes'
    Rake::Task["gitlab:setup"].invoke

    Gitlab::Database::EachDatabase.each_connection do |connection|
      # Make sure DB statistics are up to date.
      # gitlab:setup task can insert quite a bit of data, especially with MASS_INSERT=1
      # so ANALYZE can take more than default 15s statement timeout. This being a dev task,
      # we disable the statement timeout for ANALYZE to run and enable it back afterwards.
      connection.execute('SET statement_timeout TO 0')
      connection.execute('ANALYZE')
      connection.execute('RESET statement_timeout')
    end

    Rake::Task["gitlab:shell:setup"].invoke
  end

  desc "GitLab | Dev | Eager load application"
  task load: :environment do
    Rails.configuration.eager_load = true
    Rails.application.eager_load!
  end

  desc "GitLab | Dev | Load specific fixture"
  task 'fixtures:load', [:fixture_name] => :environment do |_, args|
    fixture_name = args.fixture_name

    if fixture_name.nil?
      puts "No fixture name was provided"
      next
    end

    ENV['FIXTURE_PATH'] = 'db/fixtures/development/'
    ENV['FILTER'] = args.fixture_name

    Rake::Task['db:seed_fu'].invoke
  end

  # If there are any clients connected to the DB, PostgreSQL won't let
  # you drop the database. It's possible that Sidekiq, Puma, or
  # some other client will be hanging onto a connection, preventing
  # the DROP DATABASE from working. To workaround this problem, this
  # method terminates all the connections so that a subsequent DROP
  # will work.
  desc "Used to drop all connections in development"
  task :terminate_all_connections do
    # In production, we might want to prevent ourselves from shooting
    # ourselves in the foot, so let's only do this in a test or
    # development environment.
    unless Rails.env.production?
      cmd = <<~SQL
      SELECT pg_terminate_backend(pg_stat_activity.pid)
      FROM pg_stat_activity
      WHERE datname = current_database()
        AND pid <> pg_backend_pid();
      SQL

      Gitlab::Database::EachDatabase.each_connection(include_shared: false) do |connection|
        connection.execute(cmd)
      rescue ActiveRecord::NoDatabaseError
      end

      # Clear connections opened by this rake task too
      ActiveRecord::Base.clear_all_connections! # rubocop:disable Database/MultipleDatabases
    end
  end

  databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

  namespace :copy_db do
    ALLOWED_DATABASES = %w[ci sec].freeze

    ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
      next unless ALLOWED_DATABASES.include?(name)

      desc "Copies the #{name} database from the main database"
      task name => :environment do
        Rake::Task["dev:terminate_all_connections"].invoke

        db_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: name)

        ApplicationRecord.connection.create_database(db_config.database, template: ApplicationRecord.connection_db_config.database)
      rescue ActiveRecord::DatabaseAlreadyExists
        warn "Database '#{db_config.database}' already exists"
      end
    end
  end
end
