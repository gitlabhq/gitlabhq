# frozen_string_literal: true

class DropInt4ColumnForPushEventPayloads < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    remove_column :push_event_payloads, :event_id_convert_to_bigint, :integer, null: false, default: 0
  end
end
