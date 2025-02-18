# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOperationsScopesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_operations_scopes_project_id
      feature_category :feature_flags
    end
  end
end
