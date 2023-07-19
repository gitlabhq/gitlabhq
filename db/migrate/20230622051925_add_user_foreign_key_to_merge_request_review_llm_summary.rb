# frozen_string_literal: true

class AddUserForeignKeyToMergeRequestReviewLlmSummary < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :merge_request_review_llm_summaries, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :merge_request_review_llm_summaries, column: :user_id
    end
  end
end
