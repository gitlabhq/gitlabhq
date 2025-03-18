# frozen_string_literal: true

class AddMergeRequestUserMentionsProjectIdFk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  def up
    add_concurrent_foreign_key(
      :merge_request_user_mentions,
      :projects,
      column: :project_id,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :merge_request_user_mentions, column: :project_id, reverse_lock_order: true
    end
  end
end
