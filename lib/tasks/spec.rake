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

  desc 'GitLab | Rspec | Run model specs'
  task :models do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @models)
    ]
    run_commands(cmds)
  end

  desc 'GitLab | Rspec | Run service specs'
  task :services do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @services)
    ]
    run_commands(cmds)
  end

  desc 'GitLab | Rspec | Run lib specs'
  task :lib do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @lib)
    ]
    run_commands(cmds)
  end

  desc 'GitLab | Rspec | Run other specs'
  task :other do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag ~@api --tag ~@feature --tag ~@models --tag ~@lib --tag ~@services)
    ]
    run_commands(cmds)
  end
end

desc "GitLab | Run specs"
task :spec do
  cmds = [
    %W(rake gitlab:setup),
    %W(rspec spec),
  ]
  run_commands(cmds)
end

def run_commands(cmds)
  cmds.each do |cmd|
    system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd) or raise("#{cmd} failed!")
  end
end
