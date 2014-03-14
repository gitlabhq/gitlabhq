Rake::Task["spinach"].clear

desc "GITLAB | Run spinach"
task :spinach do
  cmds = [
    %W(rake gitlab:setup),
    %W(spinach),
  ]

  cmds.each do |cmd|
    system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd)
    raise "#{cmd} failed!" unless $?.exitstatus.zero?
  end
end
