# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIncidentManagementPendingAlertEscalationsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_incident_management_pending_alert_escalations_project_id
      feature_category :incident_management
    end
  end
end
