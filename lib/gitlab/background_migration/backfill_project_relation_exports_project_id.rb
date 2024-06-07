# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProjectRelationExportsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_project_relation_exports_project_id
      feature_category :importers
    end
  end
end
