# frozen_string_literal: true

class CreateCdVersionSetEntries < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    create_table :cd_version_set_entries do |t|
      t.bigint :group_id, null: false
      t.bigint :version_set_id, null: false
      t.bigint :version_id, null: false
      t.bigint :service_id, null: false
      t.timestamps_with_timezone null: false

      t.index :group_id
      t.index [:version_set_id, :version_id], unique: true
      t.index [:version_set_id, :service_id], unique: true
      t.index :version_id
      t.index :service_id
    end
  end
end
