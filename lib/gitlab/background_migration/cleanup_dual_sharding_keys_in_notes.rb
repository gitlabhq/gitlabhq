# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Nulls out namespace_id on notes rows where both namespace_id and project_id
    # are populated. project_id is the authoritative sharding key for project-scoped
    # notes, so namespace_id must be cleared to satisfy the eventual single-key
    # NOT NULL constraint.
    #
    # See: https://gitlab.com/gitlab-org/gitlab/-/work_items/569520
    class CleanupDualShardingKeysInNotes < BatchedMigrationJob
      operation_name :cleanup_dual_sharding_keys
      feature_category :team_planning

      scope_to ->(relation) { relation.where('namespace_id IS NOT NULL AND project_id IS NOT NULL') } # rubocop:disable Database/AvoidScopeTo -- both columns are indexed

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(namespace_id: nil)
        end
      end
    end
  end
end
