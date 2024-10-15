# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIncidentManagementEscalationRulesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_incident_management_escalation_rules_project_id
      feature_category :incident_management
    end
  end
end
