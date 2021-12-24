# frozen_string_literal: true

class AddGroupCrmSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    create_table :group_crm_settings, id: false do |t|
      t.references :group, primary_key: true, foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.timestamps_with_timezone
      t.boolean :enabled, null: false, default: false
    end
  end
end
