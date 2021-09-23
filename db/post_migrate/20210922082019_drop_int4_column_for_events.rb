# frozen_string_literal: true

class DropInt4ColumnForEvents < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    remove_column :events, :id_convert_to_bigint, :integer, null: false, default: 0
  end
end
