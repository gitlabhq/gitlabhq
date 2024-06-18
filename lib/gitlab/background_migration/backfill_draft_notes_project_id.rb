# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDraftNotesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_draft_notes_project_id
      feature_category :code_review_workflow
    end
  end
end
