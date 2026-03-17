# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RenameManageRepositoryStorageMovePermissionInGranularScopes < BatchedMigrationJob
      include Gitlab::Database::MigrationHelpers::GranularScopePermissions

      feature_category :permissions
    end
  end
end
