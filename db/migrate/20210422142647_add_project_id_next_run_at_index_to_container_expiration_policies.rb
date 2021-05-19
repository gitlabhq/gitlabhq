# frozen_string_literal: true

class AddProjectIdNextRunAtIndexToContainerExpirationPolicies < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'idx_container_exp_policies_on_project_id_next_run_at'

  def up
    add_concurrent_index :container_expiration_policies, [:project_id, :next_run_at], name: INDEX_NAME, where: 'enabled = true'
  end

  def down
    remove_concurrent_index :container_expiration_policies, [:project_id, :next_run_at], name: INDEX_NAME
  end
end
