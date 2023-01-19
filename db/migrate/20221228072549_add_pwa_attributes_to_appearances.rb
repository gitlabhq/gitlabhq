# frozen_string_literal: true

class AddPwaAttributesToAppearances < Gitlab::Database::Migration[2.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  def up
    add_column :appearances, :pwa_name, :text
    add_column :appearances, :pwa_description, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :appearances, :pwa_name
    remove_column :appearances, :pwa_description
  end
end
