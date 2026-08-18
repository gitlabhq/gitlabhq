# frozen_string_literal: true

module Namespaces
  class StatePropagationWorker
    include ApplicationWorker

    data_consistency :sticky

    queue_namespace :namespaces
    feature_category :groups_and_projects
    urgency :low
    defer_on_database_health_signal :gitlab_main, [:namespaces], 1.minute
    idempotent!
    deduplicate :until_executed, including_scheduled: true
    concurrency_limit -> { 200 }

    loggable_arguments 1

    def perform(namespace_id, target_state)
      Namespaces::StatePropagationService.new(namespace_id, target_state).execute
    end
  end
end
