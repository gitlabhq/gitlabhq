# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RenameManageRepositoryStorageMovePermissionInGranularScopes < BatchedMigrationJob
      include Gitlab::Database::MigrationHelpers::GranularScopePermissions

      RENAMES = { 'manage_repository_storage_move' => 'create_repository_storage_move' }.freeze

      # Matches the 2 args passed by the already-queued post-deploy migration.
      # The args are ignored at runtime; RENAMES is the source of truth.
      def self.job_arguments_count
        2
      end

      feature_category :permissions
    end
  end
end
