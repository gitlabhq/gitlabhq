# frozen_string_literal: true

class AddDuoNanoEnabledToAiSettings < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :ai_settings, :duo_nano_features_enabled, :boolean, null: true
  end
end
