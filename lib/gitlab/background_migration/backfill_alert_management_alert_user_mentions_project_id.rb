# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillAlertManagementAlertUserMentionsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_alert_management_alert_user_mentions_project_id
      feature_category :incident_management
    end
  end
end
