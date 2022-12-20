# frozen_string_literal: true

class AddShortTitleToAppearances < Gitlab::Database::Migration[2.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20221115085813_add_limit_to_appereances_short_title.rb
  def change
    add_column :appearances, :short_title, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
