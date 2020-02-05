# frozen_string_literal: true

class ChangeBroadcastMessageIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :broadcast_messages, %i(ends_at broadcast_type id), name: 'index_broadcast_message_on_ends_at_and_broadcast_type_and_id'
    remove_concurrent_index_by_name :broadcast_messages, :index_broadcast_messages_on_starts_at_and_ends_at_and_id
  end

  def down
    add_concurrent_index :broadcast_messages, %i(starts_at ends_at id), name: 'index_broadcast_messages_on_starts_at_and_ends_at_and_id'
    remove_concurrent_index_by_name :broadcast_messages, :index_broadcast_message_on_ends_at_and_broadcast_type_and_id
  end
end
