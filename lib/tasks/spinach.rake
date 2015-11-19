Rake::Task["spinach"].clear if Rake::Task.task_defined?('spinach')

namespace :spinach do
  desc "GitLab | Spinach | Run project spinach features"
  task :project do
    cmds = [
      %W(rake gitlab:setup),
      %W(spinach --tags ~@admin,~@dashboard,~@profile,~@public,~@snippets,~@commits),
    ]
    run_commands(cmds)
  end

  desc "GitLab | Spinach | Run other spinach features"
  task :other do
    cmds = [
      %W(rake gitlab:setup),
      %W(spinach --tags @admin,@dashboard,@profile,@public,@snippets,@commits),
    ]
    run_commands(cmds)
  end
end

desc "GitLab | Run spinach"
task :spinach do
  cmds = [
    %W(rake gitlab:setup),
    %W(spinach),
  ]
  run_commands(cmds)
end

def run_commands(cmds)
  cmds.each do |cmd|
    system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd) or raise("#{cmd} failed!")
  end
end