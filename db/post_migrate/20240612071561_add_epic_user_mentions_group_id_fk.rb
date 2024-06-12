# frozen_string_literal: true

class AddEpicUserMentionsGroupIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :epic_user_mentions, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :epic_user_mentions, column: :group_id
    end
  end
end
