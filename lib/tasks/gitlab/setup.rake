namespace :gitlab do
  desc "GITLAB | Setup production application"
  task setup: :environment do
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

    Rake::Task["db:setup"].invoke

    config = YAML.load(ERB.new(File.read(File.join(Rails.root, "config","database.yml"))).result)
    success = case config["adapter"]
              when /^mysql/ then
                Rake::Task["add_limits_mysql"].invoke
              when "postgresql" then
              end

    Rake::Task["db:seed_fu"].invoke
  rescue Gitlab::TaskAbortedByUserError
    puts "Quitting...".red
    exit 1
  end
end
