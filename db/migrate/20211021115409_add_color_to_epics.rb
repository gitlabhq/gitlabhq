# frozen_string_literal: true

class AddColorToEpics < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20211021124715_add_text_limit_to_epics_color
  def change
    add_column :epics, :color, :text, default: '#1068bf'
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
