namespace :gitlab do
  desc "GITLAB | Run all tests"
  task :test do
    cmds = [
      %W(rake gitlab:setup),
      %W(rake spinach),
      %W(rake spec),
      %W(rake jasmine:ci)
    ]

    cmds.each do |cmd|
      system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd)

      raise "#{cmd} failed!" unless $?.exitstatus.zero?
    end
  end
end
