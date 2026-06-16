# frozen_string_literal: true

class CreateCdApplicationFlowDefinitions < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  UNIQUE_INDEX_NAME = 'index_cd_app_flow_definitions_on_application_id_and_version'

  def change
    create_table :cd_application_flow_definitions do |t|
      t.bigint :application_id, null: false
      t.bigint :organization_id, null: false
      t.integer :version, null: false, default: 1
      t.integer :file_store, null: false, default: 1, limit: 2
      t.timestamps_with_timezone null: false
      t.text :file, null: false, limit: 255

      t.index :organization_id
      t.index [:application_id, :version], unique: true, name: UNIQUE_INDEX_NAME
    end
  end
end
