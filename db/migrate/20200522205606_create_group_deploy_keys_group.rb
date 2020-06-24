# frozen_string_literal: true

class CreateGroupDeployKeysGroup < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :group_deploy_keys_groups do |t|
        t.timestamps_with_timezone

        t.references :group, index: false, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }
        t.references :group_deploy_key, null: false, foreign_key: { on_delete: :cascade }

        t.index [:group_id, :group_deploy_key_id], unique: true, name: 'index_group_deploy_keys_group_on_group_deploy_key_and_group_ids'
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :group_deploy_keys_groups
    end
  end
end
