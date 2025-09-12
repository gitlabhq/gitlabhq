# frozen_string_literal: true

class CreateSecretRotationInfos < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  def up
    create_table :secret_rotation_infos, if_not_exists: true do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.text :secret_name, null: false, limit: 255
      t.integer :secret_metadata_version, null: false
      t.integer :rotation_interval_days, null: false

      t.timestamps_with_timezone
    end

    add_concurrent_index :secret_rotation_infos,
      [:project_id, :secret_name, :secret_metadata_version],
      unique: true,
      name: 'idx_secret_rotation_infos_project_secret'
  end

  def down
    remove_concurrent_index_by_name :secret_rotation_infos, 'idx_secret_rotation_infos_project_secret'
    drop_table :secret_rotation_infos
  end
end
