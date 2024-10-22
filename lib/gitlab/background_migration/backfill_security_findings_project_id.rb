# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSecurityFindingsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_security_findings_project_id
      feature_category :vulnerability_management
    end
  end
end
