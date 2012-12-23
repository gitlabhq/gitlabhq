namespace :gitlab do
  desc "GITLAB | Setup production application"
  task :setup => :environment do
    setup
  end

  def setup
    warn_user_is_not_gitlab

    puts "This will create the necessary database tables and seed the database."
    puts "It will overwrite data you already have."
    ask_to_continue
    puts ""

    Rake::Task["db:setup"].invoke
    Rake::Task["db:seed_fu"].invoke
    Rake::Task["gitlab:enable_automerge"].invoke
    Rake::Task["gitlab:enable_namespaces"].invoke
  rescue Gitlab::TaskAbortedByUserError
    puts "Quitting...".red
    exit 1
  end
end
