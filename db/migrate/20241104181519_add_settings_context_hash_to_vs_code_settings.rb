# frozen_string_literal: true

class AddSettingsContextHashToVsCodeSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  def up
    add_column :vs_code_settings, :settings_context_hash, :text, default: nil, null: true
    add_text_limit :vs_code_settings, :settings_context_hash, 255
  end

  def down
    remove_column :vs_code_settings, :settings_context_hash
  end
end
