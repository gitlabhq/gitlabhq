# frozen_string_literal: true

class AddExpirationPolicyCleanupStatusToContainerRepositories < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'idx_container_repositories_on_exp_cleanup_status_and_start_date'

  disable_ddl_transaction!

  def up
    unless column_exists?(:container_repositories, :expiration_policy_cleanup_status)
      add_column(:container_repositories, :expiration_policy_cleanup_status, :integer, limit: 2, default: 0, null: false)
    end

    add_concurrent_index(:container_repositories, [:expiration_policy_cleanup_status, :expiration_policy_started_at], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index(:container_repositories, [:expiration_policy_cleanup_status, :expiration_policy_started_at], name: INDEX_NAME)

    if column_exists?(:container_repositories, :expiration_policy_cleanup_status)
      remove_column(:container_repositories, :expiration_policy_cleanup_status)
    end
  end
end
