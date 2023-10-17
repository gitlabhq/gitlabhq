# frozen_string_literal: true

class AddUuidAndVersionToVsCodeSetting < Gitlab::Database::Migration[2.1]
  def up
    add_column :vs_code_settings, :uuid, :uuid, null: true, default: false
    add_column :vs_code_settings, :version, :integer, null: true, default: false
  end

  def down
    remove_column :vs_code_settings, :uuid
    remove_column :vs_code_settings, :version
  end
end
