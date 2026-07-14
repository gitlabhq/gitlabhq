# frozen_string_literal: true

class CreateCdEnvironmentDriverBindings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  UNIQUE_INDEX_NAME = 'index_cd_env_driver_bindings_on_environment_id_and_version'
  ORG_INDEX_NAME = 'index_cd_env_driver_bindings_on_organization_id'
  CONSTRAINT_NAME = 'check_cd_env_driver_bindings_driver_config_is_hash'

  def up
    create_table :cd_environment_driver_bindings do |t|
      t.bigint :organization_id, null: false
      t.bigint :environment_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :version, null: false, default: 1
      t.text :driver_ref, null: false, limit: 255
      t.jsonb :driver_config, null: false, default: {}

      t.index [:environment_id, :version], unique: true, name: UNIQUE_INDEX_NAME
      t.index :organization_id, name: ORG_INDEX_NAME
    end

    add_check_constraint :cd_environment_driver_bindings, "(jsonb_typeof(driver_config) = 'object')", CONSTRAINT_NAME
  end

  def down
    drop_table :cd_environment_driver_bindings
  end
end
