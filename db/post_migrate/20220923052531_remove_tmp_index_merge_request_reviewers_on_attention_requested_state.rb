# frozen_string_literal: true

class RemoveTmpIndexMergeRequestReviewersOnAttentionRequestedState < Gitlab::Database::Migration[2.0]
  INDEX_NAME = "tmp_index_merge_request_reviewers_on_attention_requested_state"
  ATTENTION_REQUESTED_STATE = 2

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :merge_request_reviewers, INDEX_NAME
  end

  def down
    add_concurrent_index :merge_request_reviewers, [:id],
      where: "state = #{ATTENTION_REQUESTED_STATE}",
      name: INDEX_NAME
  end
end
