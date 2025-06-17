# frozen_string_literal: true

module Ci
  class SafeDisablePipelineVariablesService < BaseService
    PROJECTS_BATCH_SIZE = 500

    def initialize(current_user:, group:)
      @current_user = current_user
      @parent_group = group
    end

    def execute
      return ServiceResponse.error(message: 'You are not authorized to perform this action') unless authorized?

      updated_count = 0

      parent_group.self_and_descendants.each_batch do |group_batch|
        all_projects_ci_cd_settings = ProjectCiCdSetting.for_namespace(group_batch)
          .with_pipeline_variables_enabled

        all_projects_ci_cd_settings
          .each_batch(of: PROJECTS_BATCH_SIZE) do |ci_cd_settings|
          batch_updated_count =
            ProjectCiCdSetting.bulk_restrict_pipeline_variables!(
              project_ids: ProjectCiCdSetting.project_ids_not_using_variables(ci_cd_settings, PROJECTS_BATCH_SIZE)
            )

          updated_count += batch_updated_count
        end
      end

      ServiceResponse.success(payload: { updated_count: updated_count })
    end

    private

    attr_reader :current_user, :parent_group

    def authorized?
      current_user.can?(:admin_group, parent_group)
    end
  end
end
