# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RenameMergeRequestDependencyAndPackagePipelinePermissions < BatchedMigrationJob
      include Gitlab::Database::MigrationHelpers::GranularScopePermissions

      RENAMES = {
        'read_merge_request_dependency' => 'read_merge_request',
        'create_merge_request_dependency' => 'create_merge_request',
        'delete_merge_request_dependency' => 'delete_merge_request',
        'read_package_pipeline' => 'read_package'
      }.freeze

      feature_category :permissions
    end
  end
end
