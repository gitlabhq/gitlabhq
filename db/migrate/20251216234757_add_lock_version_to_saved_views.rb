# frozen_string_literal: true

class AddLockVersionToSavedViews < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def change
    add_column :saved_views, :lock_version, :integer, default: 0, null: false
  end
end
