# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class UpdateRequireDpopForManageApiEndpointsToFalse < BatchedMigrationJob
      feature_category :system_access
      operation_name :update_require_dpop_for_manage_api_endpoints_to_false

      scope_to ->(relation) { relation.where(require_dpop_for_manage_api_endpoints: true) }

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(require_dpop_for_manage_api_endpoints: false)
        end
      end
    end
  end
end
