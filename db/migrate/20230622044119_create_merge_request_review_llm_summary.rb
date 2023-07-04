# frozen_string_literal: true

class CreateMergeRequestReviewLlmSummary < Gitlab::Database::Migration[2.1]
  INDEX_NAME = "index_merge_request_review_llm_summaries_on_mr_diff_id"

  def change
    create_table :merge_request_review_llm_summaries do |t|
      t.references :user, null: true, index: true
      t.references :review, null: false, index: true
      t.references :merge_request_diff, null: false, index: { name: INDEX_NAME }
      t.timestamps_with_timezone null: false
      t.integer :provider, null: false, limit: 2
      t.text :content, null: false, limit: 2056
    end
  end
end
