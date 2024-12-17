# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillStatusPagePublishedIncidentsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_status_page_published_incidents_namespace_id
      feature_category :incident_management
    end
  end
end
