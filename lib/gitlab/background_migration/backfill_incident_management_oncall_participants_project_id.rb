# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIncidentManagementOncallParticipantsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_incident_management_oncall_participants_project_id
      feature_category :incident_management
    end
  end
end
