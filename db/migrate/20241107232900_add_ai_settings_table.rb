# frozen_string_literal: true

class AddAiSettingsTable < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  def up
    create_table :ai_settings do |t|
      t.text :ai_gateway_url, limit: 2048 # Most browsers support URLs up to 2048 characters
      t.boolean :singleton, null: false, default: true, comment: 'Always true, used for singleton enforcement'
    end

    add_check_constraint :ai_settings, "(singleton IS TRUE)", 'check_singleton'
    add_index :ai_settings, :singleton, unique: true
  end

  def down
    drop_table :ai_settings
  end
end
