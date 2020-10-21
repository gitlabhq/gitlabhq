# frozen_string_literal: true

class AddIndexWithProjectIdToContainerExpirationPolicies < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'idx_container_exp_policies_on_project_id_next_run_at_enabled'

  disable_ddl_transaction!

  def up
    add_concurrent_index :container_expiration_policies, [:project_id, :next_run_at, :enabled], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :container_expiration_policies, INDEX_NAME
  end
end
