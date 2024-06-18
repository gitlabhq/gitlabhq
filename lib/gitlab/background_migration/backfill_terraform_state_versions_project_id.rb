# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillTerraformStateVersionsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_terraform_state_versions_project_id
      feature_category :infrastructure_as_code
    end
  end
end
