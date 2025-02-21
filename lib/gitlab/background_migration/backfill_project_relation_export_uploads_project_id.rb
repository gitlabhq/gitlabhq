# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProjectRelationExportUploadsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_project_relation_export_uploads_project_id
      feature_category :importers
    end
  end
end
