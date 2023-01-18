# frozen_string_literal: true

class AddPwaIconToAppearances < Gitlab::Database::Migration[2.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  def up
    add_column :appearances, :pwa_icon, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :appearances, :pwa_icon
  end
end
