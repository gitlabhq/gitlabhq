Rake::Task["spec"].clear if Rake::Task.task_defined?('spec')

namespace :spec do
  desc 'GitLab | Rspec | Run request specs'
  task :api do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @api)
    ]
    run_commands(cmds)
  end

  desc 'GitLab | Rspec | Run feature specs'
  task :feature do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @feature)
    ]
    run_commands(cmds)
  end

  desc 'GitLab | Rspec | Run benchmark specs'
  task :benchmark do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @benchmark)
    ]
    run_commands(cmds)
  end

  desc 'GitLab | Rspec | Run other specs'
  task :other do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag ~@api --tag ~@feature --tag ~@benchmark)
    ]
    run_commands(cmds)
  end
end

desc "GitLab | Run specs"
task :spec do
  cmds = [
    %W(rake gitlab:setup),
    %W(rspec spec --tag ~@benchmark),
  ]
  run_commands(cmds)
end

def run_commands(cmds)
  cmds.each do |cmd|
    system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd) or raise("#{cmd} failed!")
  end
end
