# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillExternalStatusChecksProtectedBranchesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_external_status_checks_protected_branches_project_id
      feature_category :compliance_management
    end
  end
end
