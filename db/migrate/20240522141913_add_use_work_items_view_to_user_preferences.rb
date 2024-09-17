# frozen_string_literal: true

class AddUseWorkItemsViewToUserPreferences < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :user_preferences, :use_work_items_view, :boolean, default: false, null: false
  end
end
