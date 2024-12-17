# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssuableMetricImagesNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_issuable_metric_images_namespace_id
      feature_category :observability
    end
  end
end
