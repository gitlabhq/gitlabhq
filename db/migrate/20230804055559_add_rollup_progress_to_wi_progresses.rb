# frozen_string_literal: true

class AddRollupProgressToWiProgresses < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :work_item_progresses, :rollup_progress, :boolean, default: true, null: false
  end
end
