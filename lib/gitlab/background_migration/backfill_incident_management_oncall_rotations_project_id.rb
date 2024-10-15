# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIncidentManagementOncallRotationsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_incident_management_oncall_rotations_project_id
      feature_category :incident_management
    end
  end
end
