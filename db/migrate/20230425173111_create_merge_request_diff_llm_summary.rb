# frozen_string_literal: true

class CreateMergeRequestDiffLlmSummary < Gitlab::Database::Migration[2.1]
  INDEX_NAME = "index_merge_request_diff_llm_summaries_on_mr_diff_id"

  def change
    create_table :merge_request_diff_llm_summaries do |t|
      t.bigint :user_id, null: true, index: true
      t.bigint :merge_request_diff_id, null: false, index:
        { name: INDEX_NAME }
      t.timestamps_with_timezone null: false
      t.integer :provider, null: false, limit: 2
      t.text :content, null: false, limit: 2056
    end
  end
end
