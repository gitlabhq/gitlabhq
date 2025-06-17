# frozen_string_literal: true

class AddDarkColorSchemeIdToUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :user_preferences, :dark_color_scheme_id, :smallint
  end
end
