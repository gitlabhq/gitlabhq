# frozen_string_literal: true

class AddColorModeIdToUsers < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  enable_lock_retries!

  # From lib/gitlab/color_modes.rb
  DEFAULT_COLOR_MODE = 1

  def change
    # rubocop:disable Migration/PreventAddingColumns -- consistent with theme_id
    add_column :users, :color_mode_id, :smallint, default: DEFAULT_COLOR_MODE, null: false, if_not_exists: true
    # rubocop:enable Migration/PreventAddingColumns
  end
end
