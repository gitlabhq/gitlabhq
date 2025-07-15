# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPipelineSdAndCsAnalyzerProjectStatuses < BatchedMigrationJob
      feature_category :security_asset_inventories
      operation_name :backfill_pipeline_sd_and_cs_analyzer_project_statuses

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillPipelineSdAndCsAnalyzerProjectStatuses.prepend_mod
