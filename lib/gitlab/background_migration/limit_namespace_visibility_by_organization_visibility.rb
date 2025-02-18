# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class LimitNamespaceVisibilityByOrganizationVisibility < BatchedMigrationJob
      PRIVATE = 0
      DEFAULT_ORG_ID = 1

      operation_name :limit_namespace_visibility_by_organization_visibility
      scope_to ->(relation) { relation.where.not(visibility_level: PRIVATE) }
      feature_category :groups_and_projects

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .joins('INNER JOIN organizations ON namespaces.organization_id = organizations.id')
            .where.not(organization_id: DEFAULT_ORG_ID)
            .where('namespaces.visibility_level > organizations.visibility_level')
            .update_all(visibility_level: PRIVATE)
        end
      end
    end
  end
end
