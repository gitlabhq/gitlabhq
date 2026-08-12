# frozen_string_literal: true

class CreateCdRolloutSteps < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.3'

  UNIQUE_INDEX_NAME = 'index_cd_rollout_steps_on_rollout_id_and_path'
  ORG_INDEX_NAME = 'index_cd_rollout_steps_on_organization_id'
  ROLLOUT_ENVIRONMENT_INDEX_NAME = 'index_cd_rollout_steps_on_rollout_environment_id'
  PARAMS_CONSTRAINT_NAME = 'check_cd_rollout_steps_params_is_hash'

  def up
    create_table :cd_rollout_steps do |t|
      t.bigint :organization_id, null: false
      t.bigint :rollout_id, null: false
      t.bigint :rollout_environment_id
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :started_at
      t.datetime_with_timezone :finished_at
      t.integer :state, null: false, default: 0, limit: 2
      t.text :path, null: false, limit: 255
      t.text :parent_path, limit: 255
      t.text :step_type, null: false, limit: 255
      t.text :name, limit: 255
      t.text :error, limit: 2000
      t.jsonb :params

      t.index [:rollout_id, :path], unique: true, name: UNIQUE_INDEX_NAME
      t.index :organization_id, name: ORG_INDEX_NAME
      t.index :rollout_environment_id, name: ROLLOUT_ENVIRONMENT_INDEX_NAME
    end

    add_check_constraint :cd_rollout_steps, "(params IS NULL OR jsonb_typeof(params) = 'object')",
      PARAMS_CONSTRAINT_NAME
  end

  def down
    drop_table :cd_rollout_steps
  end
end
