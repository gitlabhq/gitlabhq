# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillEvidencesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_evidences_project_id
      feature_category :release_evidence
    end
  end
end
