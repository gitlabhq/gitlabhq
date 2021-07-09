# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateContainerReposOnExpCleanupStatusProjectIdStartDateIndex < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_INDEX_NAME = 'idx_container_repositories_on_exp_cleanup_status_and_start_date'
  NEW_INDEX_NAME = 'idx_container_repos_on_exp_cleanup_status_project_id_start_date'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:container_repositories, [:expiration_policy_cleanup_status, :project_id, :expiration_policy_started_at], name: NEW_INDEX_NAME)
    remove_concurrent_index(:container_repositories, [:expiration_policy_cleanup_status, :expiration_policy_started_at], name: OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(:container_repositories, [:expiration_policy_cleanup_status, :expiration_policy_started_at], name: OLD_INDEX_NAME)
    remove_concurrent_index(:container_repositories, [:expiration_policy_cleanup_status, :project_id, :expiration_policy_started_at], name: NEW_INDEX_NAME)
  end
end
