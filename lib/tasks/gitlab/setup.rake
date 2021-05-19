# frozen_string_literal: true

namespace :gitlab do
  desc "GitLab | Setup production application"
  task setup: :gitlab_environment do
    check_gitaly_connection
    setup_db
  end

  def check_gitaly_connection
    Gitlab.config.repositories.storages.each do |name, _details|
      Gitlab::GitalyClient::ServerService.new(name).info
    end
  rescue GRPC::Unavailable => ex
    puts "Failed to connect to Gitaly...".color(:red)
    puts "Error: #{ex}"
    exit 1
  end

  def setup_db
    warn_user_is_not_gitlab

    unless ENV['force'] == 'yes'
      puts "This will create the necessary database tables and seed the database."
      puts "You will lose any previous data stored in the database."
      ask_to_continue
      puts ""
    end

    # In production, we might want to prevent ourselves from shooting
    # ourselves in the foot, so let's only do this in a test or
    # development environment.
    terminate_all_connections unless Rails.env.production?

    Rake::Task["db:reset"].invoke
    Rake::Task["db:seed_fu"].invoke
  rescue Gitlab::TaskAbortedByUserError
    puts "Quitting...".color(:red)
    exit 1
  end

  # If there are any clients connected to the DB, PostgreSQL won't let
  # you drop the database. It's possible that Sidekiq, Puma, or
  # some other client will be hanging onto a connection, preventing
  # the DROP DATABASE from working. To workaround this problem, this
  # method terminates all the connections so that a subsequent DROP
  # will work.
  def self.terminate_all_connections
    cmd = <<~SQL
    SELECT pg_terminate_backend(pg_stat_activity.pid)
        FROM pg_stat_activity
        WHERE datname = current_database()
        AND pid <> pg_backend_pid();
    SQL

    ActiveRecord::Base.connection.execute(cmd)&.result_status == PG::PGRES_TUPLES_OK
  rescue ActiveRecord::NoDatabaseError
  end
end
