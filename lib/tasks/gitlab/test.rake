namespace :gitlab do
  desc "GitLab | Run all tests"
  task :test do
    cmds = [
      %w(rake brakeman),
      %w(rake rubocop),
      %w(rake spec),
      %w(rake karma)
    ]

    cmds.each do |cmd|
      system({ 'RAILS_ENV' => 'test', 'force' => 'yes' }, *cmd) || raise("#{cmd} failed!")
    end
  end
end
