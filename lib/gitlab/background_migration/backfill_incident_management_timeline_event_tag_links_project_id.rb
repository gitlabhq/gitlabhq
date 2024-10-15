# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIncidentManagementTimelineEventTagLinksProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_incident_management_timeline_event_tag_links_project_id
      feature_category :incident_management
    end
  end
end
