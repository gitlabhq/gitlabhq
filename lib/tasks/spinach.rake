Rake::Task["spinach"].clear if Rake::Task.task_defined?('spinach')

desc "GITLAB | Run spinach"
task :spinach do
  cmds = [
    %W(rake gitlab:setup),
    %W(spinach),
  ]

  cmds.each do |cmd|
    system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd) or raise("#{cmd} failed!")
  end
end
