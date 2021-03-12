# frozen_string_literal: true

class AddIndexToEnvironmentsTier < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_environments_on_project_id_and_tier'

  DOWNTIME = false

  def up
    add_concurrent_index :environments, [:project_id, :tier], where: 'tier IS NOT NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index :environments, :state, name: INDEX_NAME
  end
end
