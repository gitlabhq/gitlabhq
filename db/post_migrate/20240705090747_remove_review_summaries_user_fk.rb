# frozen_string_literal: true

class RemoveReviewSummariesUserFk < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  OLD_FK_NAME = 'fk_d07eeb6392'

  def up
    remove_foreign_key_if_exists(
      :merge_request_review_llm_summaries,
      :users,
      column: :user_id,
      on_delete: :cascade,
      name: OLD_FK_NAME,
      reverse_lock_order: true
    )
  end

  def down
    add_concurrent_foreign_key(
      :merge_request_review_llm_summaries,
      :users,
      column: :user_id,
      on_delete: :cascade,
      name: OLD_FK_NAME,
      reverse_lock_order: true
    )
  end
end
