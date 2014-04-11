namespace :testing do
  desc 'GITLAB | Run model specs'
  task :models do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @models)
    ]
    run_commands(cmds)
  end

  desc 'GITLAB | Run feature specs'
  task :features do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @features)
    ]
    run_commands(cmds)
  end

  desc 'GITLAB | Run other specs'
  task :other do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag ~@models --tag ~@features)
    ]
    run_commands(cmds)
  end

  def run_commands(cmds)
    cmds.each do |cmd|
      system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd)
      raise "#{cmd} failed!" unless $?.exitstatus.zero?
    end
  end
end
