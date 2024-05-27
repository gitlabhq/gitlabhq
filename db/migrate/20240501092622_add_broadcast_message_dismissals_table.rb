# frozen_string_literal: true

class AddBroadcastMessageDismissalsTable < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  INDEX_NAME = 'index_broadcast_dismissals_on_user_id_and_broadcast_message_id'

  def up
    create_table :user_broadcast_message_dismissals do |t|
      t.bigint :user_id, null: false
      t.bigint :broadcast_message_id, null: false
      t.datetime_with_timezone :expires_at
      t.timestamps_with_timezone null: false

      t.index :broadcast_message_id
    end

    add_index :user_broadcast_message_dismissals, [:user_id, :broadcast_message_id], unique: true, name: INDEX_NAME
  end

  def down
    drop_table :user_broadcast_message_dismissals
  end
end
