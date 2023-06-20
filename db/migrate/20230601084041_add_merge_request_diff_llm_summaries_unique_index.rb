# frozen_string_literal: true

class AddMergeRequestDiffLlmSummariesUniqueIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'unique_merge_request_diff_llm_summaries_on_mr_diff_id'
  OLD_INDEX_NAME = 'index_merge_request_diff_llm_summaries_on_mr_diff_id'

  def up
    add_concurrent_index :merge_request_diff_llm_summaries, :merge_request_diff_id, name: INDEX_NAME, unique: true
    remove_concurrent_index_by_name :merge_request_diff_llm_summaries, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :merge_request_diff_llm_summaries, :merge_request_diff_id, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :merge_request_diff_llm_summaries, INDEX_NAME
  end
end
