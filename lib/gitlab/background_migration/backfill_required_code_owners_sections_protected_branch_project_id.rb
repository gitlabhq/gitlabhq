# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillRequiredCodeOwnersSectionsProtectedBranchProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_required_code_owners_sections_protected_branch_project_id
      feature_category :source_code_management
    end
  end
end
