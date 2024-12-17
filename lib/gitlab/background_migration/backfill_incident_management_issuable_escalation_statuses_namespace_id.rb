# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIncidentManagementIssuableEscalationStatusesNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_incident_management_issuable_escalation_statuses_namespace_id
      feature_category :incident_management
    end
  end
end
