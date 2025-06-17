# frozen_string_literal: true

module Ci
  class SafeDisablePipelineVariablesWorker
    include ApplicationWorker

    data_consistency :sticky

    feature_category :ci_variables
    urgency :low
    idempotent!

    defer_on_database_health_signal :gitlab_main, [:namespaces, :project_ci_cd_settings], 1.minute

    attr_accessor :group_id, :current_user_id

    def perform(current_user_id, group_id)
      current_user = UserFinder.new(current_user_id).find_by_id
      return unless current_user

      group = ::Group.find_by_id(group_id)
      return unless group

      result = Ci::SafeDisablePipelineVariablesService.new(
        current_user: current_user, group: group
      ).execute

      return unless result.success?

      log_extra_metadata_on_done(:disabled_pipeline_variables_count, result.payload[:updated_count])
    end
  end
end
