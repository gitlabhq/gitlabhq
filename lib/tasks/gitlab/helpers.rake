# frozen_string_literal: true

# Prevent StateMachine warnings from outputting during a cron task
StateMachines::Machine.ignore_method_conflicts = true if ENV['CRON']

task :gitlab_environment do
  Rake::Task[:environment].invoke unless ENV['SKIP_RAILS_ENV_IN_RAKE']

  extend SystemCheck::Helpers
end
