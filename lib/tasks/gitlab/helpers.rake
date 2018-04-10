# Prevent StateMachine warnings from outputting during a cron task
StateMachines::Machine.ignore_method_conflicts = true if ENV['CRON']

task gitlab_environment: :environment do
  extend SystemCheck::Helpers
end
