# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillAlertManagementAlertMetricImagesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_alert_management_alert_metric_images_project_id
      feature_category :incident_management
    end
  end
end
