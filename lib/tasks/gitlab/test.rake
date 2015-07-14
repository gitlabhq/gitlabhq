namespace :gitlab do
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
end
