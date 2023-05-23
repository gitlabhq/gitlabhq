# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class removes invalid `protected_environment_deploy_access_levels.group_id` records.
    class RemoveInvalidDeployAccessLevelGroups < BatchedMigrationJob
      operation_name :remove_invalid_deploy_access_level_groups
      feature_category :database

      scope_to ->(relation) do
        relation.joins('INNER JOIN namespaces ON namespaces.id = protected_environment_deploy_access_levels.group_id')
                .where.not(protected_environment_deploy_access_levels: { group_id: nil })
                .where("namespaces.type = 'User'")
      end

      def perform
        each_sub_batch(&:delete_all)
      end
    end
  end
end
