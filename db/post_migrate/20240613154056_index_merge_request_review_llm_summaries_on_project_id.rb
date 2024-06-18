# frozen_string_literal: true

class IndexMergeRequestReviewLlmSummariesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_request_review_llm_summaries_on_project_id'

  def up
    add_concurrent_index :merge_request_review_llm_summaries, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_review_llm_summaries, INDEX_NAME
  end
end
