# frozen_string_literal: true

class AddIndexToTargetedMessageIdTargetedMessageDismissals < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  TABLE_NAME = 'targeted_message_dismissals'
  OLD_INDEX_NAME = 'index_targeted_message_dismissals_on_user_id'
  NEW_INDEX_NAME = 'index_targeted_message_dismissals_on_targeted_message_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index(TABLE_NAME, [:targeted_message_id], name: NEW_INDEX_NAME)

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, [:user_id], name: OLD_INDEX_NAME)

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
