# frozen_string_literal: true

class CreateCdRolloutEnvironments < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  UNIQUE_INDEX_NAME = 'index_cd_rollout_environments_on_rollout_and_environment'
  ORG_INDEX_NAME = 'index_cd_rollout_environments_on_organization_id'
  ENVIRONMENT_INDEX_NAME = 'index_cd_rollout_environments_on_environment_id'
  DRIVER_BINDING_INDEX_NAME = 'index_cd_rollout_environments_on_driver_binding_id'
  PREVIOUS_VS_INDEX_NAME = 'index_cd_rollout_environments_on_previous_version_set_id'

  def change
    create_table :cd_rollout_environments do |t|
      t.bigint :organization_id, null: false
      t.bigint :rollout_id, null: false
      t.bigint :environment_id, null: false
      t.bigint :driver_binding_id, null: false
      t.bigint :previous_version_set_id
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :started_at
      t.datetime_with_timezone :finished_at
      t.integer :position, null: false
      t.integer :state, null: false, default: 0, limit: 2

      t.index [:rollout_id, :environment_id], unique: true, name: UNIQUE_INDEX_NAME
      t.index :organization_id, name: ORG_INDEX_NAME
      t.index :environment_id, name: ENVIRONMENT_INDEX_NAME
      t.index :driver_binding_id, name: DRIVER_BINDING_INDEX_NAME
      t.index :previous_version_set_id, name: PREVIOUS_VS_INDEX_NAME
    end
  end
end
