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
    puts Rainbow("Failed to connect to Gitaly...").red
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
    Rake::Task["dev:terminate_all_connections"].invoke unless Rails.env.production?

    Rake::Task["db:reset"].invoke
    Rake::Task["gitlab:db:lock_writes"].invoke
    Rake::Task["db:seed_fu"].invoke
  rescue Gitlab::TaskAbortedByUserError
    puts Rainbow("Quitting...").red
    exit 1
  end
end
