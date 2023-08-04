# frozen_string_literal: true

class AddLabelLockOnMerge < Gitlab::Database::Migration[2.1]
  def change
    add_column :labels, :lock_on_merge, :boolean, default: false, null: false
  end
end
