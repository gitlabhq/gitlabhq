# frozen_string_literal: true

class AddProjectsSortingFieldToUserPreferences < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def up
    add_column :user_preferences, :projects_sort, :string, limit: 64
  end
  # rubocop:enable Migration/PreventStrings

  def down
    remove_column :user_preferences, :projects_sort
  end
end
