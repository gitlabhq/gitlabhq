# frozen_string_literal: true

return if Rails.env.production?

Rake::Task["spec"].clear if Rake::Task.task_defined?('spec')

namespace :spec do
  desc 'GitLab | RSpec | Run unit tests'
  RSpec::Core::RakeTask.new(:unit, :rspec_opts) do |t, args|
    require_dependency 'quality/test_level'
    t.pattern = Quality::TestLevel.new.pattern(:unit)
    t.rspec_opts = args[:rspec_opts]
  end

  desc 'GitLab | RSpec | Run integration tests'
  RSpec::Core::RakeTask.new(:integration, :rspec_opts) do |t, args|
    require_dependency 'quality/test_level'
    t.pattern = Quality::TestLevel.new.pattern(:integration)
    t.rspec_opts = args[:rspec_opts]
  end

  desc 'GitLab | RSpec | Run system tests'
  RSpec::Core::RakeTask.new(:system, :rspec_opts) do |t, args|
    require_dependency 'quality/test_level'
    t.pattern = Quality::TestLevel.new.pattern(:system)
    t.rspec_opts = args[:rspec_opts]
  end

  desc '[Deprecated] Use the "bin/rspec --tag api" instead'
  task :api do
    cmds = [
      %w(rake gitlab:setup),
      %w(rspec spec --tag @api)
    ]
    run_commands(cmds)
  end

  desc '[Deprecated] Use the "spec:system" task instead'
  task :feature do
    cmds = [
      %w(rake gitlab:setup),
      %w(rspec spec --tag @feature)
    ]
    run_commands(cmds)
  end

  desc '[Deprecated] Use "bin/rspec spec/models" instead'
  task :models do
    cmds = [
      %w(rake gitlab:setup),
      %w(rspec spec --tag @models)
    ]
    run_commands(cmds)
  end

  desc '[Deprecated] Use "bin/rspec spec/services" instead'
  task :services do
    cmds = [
      %w(rake gitlab:setup),
      %w(rspec spec --tag @services)
    ]
    run_commands(cmds)
  end

  desc '[Deprecated] Use "bin/rspec spec/lib" instead'
  task :lib do
    cmds = [
      %w(rake gitlab:setup),
      %w(rspec spec --tag @lib)
    ]
    run_commands(cmds)
  end
end

desc "GitLab | Run specs"
task :spec do
  cmds = [
    %w(rake gitlab:setup),
    %w(rspec spec)
  ]
  run_commands(cmds)
end

def run_commands(cmds)
  cmds.each do |cmd|
    system({ 'RAILS_ENV' => 'test', 'force' => 'yes' }, *cmd) || raise("#{cmd} failed!")
  end
end
