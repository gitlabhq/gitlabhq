namespace :gitlab do
<<<<<<< HEAD
  desc "GitLab | Run all tests"
  task :test do
    cmds = [
      %W(rake brakeman),
      %W(rake rubocop),
      %W(rake spinach),
      %W(rake spec),
      %W(rake teaspoon)
    ]

    cmds.each do |cmd|
      system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd) or raise("#{cmd} failed!")
    end
  end
=======
  desc "GITLAB | Run both spinach and rspec"
  task test: ['db:setup', 'spinach', 'spec']
<<<<<<< HEAD
>>>>>>> origin/5-4-stable
=======
>>>>>>> origin/5-4-stable
end
