# frozen_string_literal: true

class CreateCdServiceEnvironmentHealths < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  UNIQUE_INDEX_NAME = 'index_cd_service_env_healths_on_service_and_environment'
  ORG_INDEX_NAME = 'index_cd_service_env_healths_on_organization_id'
  ENVIRONMENT_INDEX_NAME = 'index_cd_service_env_healths_on_environment_id'

  def change
    create_table :cd_service_environment_healths do |t|
      t.bigint :organization_id, null: false
      t.bigint :service_id, null: false
      t.bigint :environment_id, null: false
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :observed_at, null: false
      t.integer :health, null: false, default: 0, limit: 2

      t.index [:service_id, :environment_id], unique: true, name: UNIQUE_INDEX_NAME
      t.index :organization_id, name: ORG_INDEX_NAME
      t.index :environment_id, name: ENVIRONMENT_INDEX_NAME
    end
  end
end
