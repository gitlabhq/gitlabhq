namespace :gitlab do
  desc "GITLAB | Run all tests"
  task :test do
    cmds = [
      "rake db:setup",
      "rake db:seed_fu",
      "rake spinach",
      "rake spec",
      "rake jasmine:ci"
    ]

    cmds.each do |cmd|
      system(cmd + " RAILS_ENV=test")

      raise "#{cmd} failed!" unless $?.exitstatus.zero?
    end
  end
end
