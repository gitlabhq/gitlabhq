Rake::Task["spinach"].clear if Rake::Task.task_defined?('spinach')

desc "GITLAB | Run spinach"
task :spinach do
  cmds = [
    %W(rake gitlab:setup),
    %W(spinach),
  ]
  run_commands(cmds)
end

desc "GITLAB | Run project spinach features"
task :spinach_project do
  cmds = [
    %W(rake gitlab:setup),
    %W(spinach --tags ~@admin,~@dashboard,~@profile,~@public,~@snippets),
  ]
  run_commands(cmds)
end

desc "GITLAB | Run other spinach features"
task :spinach_other do
  cmds = [
    %W(rake gitlab:setup),
    %W(spinach --tags @admin,@dashboard,@profile,@public,@snippets),
  ]
  run_commands(cmds)
end

def run_commands(cmds)
  cmds.each do |cmd|
    system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd) or raise("#{cmd} failed!")
  end
end
