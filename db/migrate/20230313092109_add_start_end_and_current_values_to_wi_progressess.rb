# frozen_string_literal: true

class AddStartEndAndCurrentValuesToWiProgressess < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :work_item_progresses, :start_value, :float, default: 0, null: false
    add_column :work_item_progresses, :end_value, :float, default: 100, null: false
    add_column :work_item_progresses, :current_value, :float, default: 0, null: false
  end
end
