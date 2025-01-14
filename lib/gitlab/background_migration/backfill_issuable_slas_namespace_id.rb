# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssuableSlasNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_issuable_slas_namespace_id
      feature_category :incident_management
    end
  end
end
