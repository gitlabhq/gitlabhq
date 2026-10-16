# frozen_string_literal: true

module Terraform
  module States
    class ScheduleDestroyCronWorker
      include ApplicationWorker
      include CronjobQueue

      defer_on_database_health_signal :gitlab_main_org, [:terraform_states], 1.minute

      data_consistency :sticky

      feature_category :infrastructure_as_code
      urgency :low

      deduplicate :until_executed
      idempotent!

      BATCH_SIZE = 1000

      def perform
        Terraform::State.ready_for_destruction.each_batch(of: BATCH_SIZE, column: :id) do |batch|
          states = batch.with_project_and_route.select do |state|
            Feature.enabled?(:terraform_state_delayed_deletion, state.project)
          end

          Terraform::States::DestroyWorker.bulk_perform_async_with_contexts(
            states,
            arguments_proc: ->(state) { [state.id] },
            context_proc: ->(state) { { project: state.project } }
          )
        end
      end
    end
  end
end
