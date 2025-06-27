# frozen_string_literal: true

module Security
  module OrchestrationConfigurationBotManagementForNamespaces
    extend ActiveSupport::Concern

    PROJECTS_BATCH_SYNC_DELAY = 1.second

    included do
      feature_category :security_policy_management
      urgency :low
      concurrency_limit -> { 200 }
    end

    def perform(namespace_id, current_user_id)
      namespace = Namespace.find_by_id(namespace_id)
      return unless namespace
      return unless namespace.security_orchestration_policy_configuration

      return unless User.id_exists?(current_user_id)

      namespace.security_orchestration_policy_configuration.all_project_ids do |project_ids|
        worker.bulk_perform_in_with_contexts(
          PROJECTS_BATCH_SYNC_DELAY,
          project_ids,
          arguments_proc: ->(project_id) { [project_id, current_user_id] },
          context_proc: ->(namespace) { { namespace: namespace } }
        )
      end

      after_perform(namespace, current_user_id)
    end

    def after_perform(namespace, current_user_id); end
  end
end
