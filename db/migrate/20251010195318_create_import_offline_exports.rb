# frozen_string_literal: true

class CreateImportOfflineExports < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    create_table :import_offline_exports do |t|
      t.bigint :user_id, index: true, null: false
      t.bigint :organization_id, index: true, null: false
      t.timestamps_with_timezone null: false
      t.integer :status, null: false, limit: 2, default: 0
      t.boolean :has_failures, default: false, null: false
      t.text :source_hostname, null: false, limit: 255
    end
  end
end
