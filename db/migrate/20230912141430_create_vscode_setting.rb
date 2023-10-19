# frozen_string_literal: true

class CreateVSCodeSetting < Gitlab::Database::Migration[2.1]
  def change
    create_table :vs_code_settings do |t|
      t.references :user, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.text :setting_type, null: false, limit: 256
      t.text :content, null: false, limit: 512.kilobytes
    end
  end
end
