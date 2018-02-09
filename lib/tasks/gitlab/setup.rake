namespace :gitlab do
  desc "GitLab | Setup production application"
  task setup: :gitlab_environment do
    setup_db
  end

  def setup_db
    warn_user_is_not_gitlab

    unless ENV['force'] == 'yes'
      puts "This will create the necessary database tables and seed the database."
      puts "You will lose any previous data stored in the database."
      ask_to_continue
      puts ""
    end

    Rake::Task["db:reset"].invoke
    Rake::Task["add_limits_mysql"].invoke
    Rake::Task["setup_postgresql"].invoke
    Rake::Task["db:seed_fu"].invoke
  rescue Gitlab::TaskAbortedByUserError
    puts "Quitting...".color(:red)
    exit 1
  end
end
