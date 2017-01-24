require 'tasks/gitlab/task_helpers'

# Prevent StateMachine warnings from outputting during a cron task
StateMachines::Machine.ignore_method_conflicts = true if ENV['CRON']

namespace :gitlab do
  include Gitlab::TaskHelpers
end
