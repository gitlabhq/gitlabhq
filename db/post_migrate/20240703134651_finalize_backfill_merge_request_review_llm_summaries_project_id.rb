# frozen_string_literal: true

class FinalizeBackfillMergeRequestReviewLlmSummariesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillMergeRequestReviewLlmSummariesProjectId"

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :merge_request_review_llm_summaries,
      column_name: :id,
      job_arguments: [:project_id, :reviews, :project_id, :review_id],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
