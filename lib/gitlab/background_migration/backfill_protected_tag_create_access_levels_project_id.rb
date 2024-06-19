# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProtectedTagCreateAccessLevelsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_protected_tag_create_access_levels_project_id
      feature_category :source_code_management
    end
  end
end
