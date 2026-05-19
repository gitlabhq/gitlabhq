# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RenameWriteWorkItemPermissionInGranularScopes < BatchedMigrationJob
      include Gitlab::Database::MigrationHelpers::GranularScopePermissions

      RENAMES = { 'write_work_item' => %w[create_work_item update_work_item] }.freeze

      # Matches the 2 args passed by the already-queued post-deploy migration.
      # The args are ignored at runtime; RENAMES is the source of truth.
      def self.job_arguments_count
        2
      end

      feature_category :permissions
    end
  end
end
