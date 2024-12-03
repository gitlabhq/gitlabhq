# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssuableResourceLinksNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_issuable_resource_links_namespace_id
      feature_category :incident_management
    end
  end
end
