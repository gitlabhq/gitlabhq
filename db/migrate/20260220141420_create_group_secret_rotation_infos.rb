# frozen_string_literal: true

class CreateGroupSecretRotationInfos < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  def up
    create_table :group_secret_rotation_infos, if_not_exists: true do |t|
      t.bigint :group_id, null: false
      t.datetime_with_timezone :next_reminder_at, null: false
      t.datetime_with_timezone :last_reminder_at, null: true
      t.timestamps_with_timezone
      t.integer :secret_metadata_version, null: false
      t.integer :rotation_interval_days, null: false
      t.text :secret_name, null: false, limit: 255
    end

    add_concurrent_index :group_secret_rotation_infos,
      [:group_id, :secret_name, :secret_metadata_version],
      unique: true,
      name: 'idx_group_secret_rotation_infos_group_secret'

    add_concurrent_index :group_secret_rotation_infos,
      :next_reminder_at,
      name: 'idx_group_secret_rotation_infos_on_next_reminder_at'
  end

  def down
    drop_table :group_secret_rotation_infos
  end
end
