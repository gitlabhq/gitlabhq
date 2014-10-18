Rake::Task["spec"].clear if Rake::Task.task_defined?('spec')

namespace :spec do
  desc 'GITLAB | Run request specs'
  task :api do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @api)
    ]
    run_commands(cmds)
  end

  desc 'GITLAB | Run feature specs'
  task :feature do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @feature)
    ]
    run_commands(cmds)
  end

  desc 'GITLAB | Run other specs'
  task :other do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag ~@api --tag ~@feature)
    ]
    run_commands(cmds)
  end
end

desc "GITLAB | Run specs"
task :spec do
  cmds = [
    %W(rake gitlab:setup),
    # TODO
    #%W(rspec spec),
    %W(rspec ./spec/controllers/edit_tree_controller_spec.rb:70),
  ]
  run_commands(cmds)
end

def run_commands(cmds)
  cmds.each do |cmd|
    system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd) or raise("#{cmd} failed!")
  end
end
