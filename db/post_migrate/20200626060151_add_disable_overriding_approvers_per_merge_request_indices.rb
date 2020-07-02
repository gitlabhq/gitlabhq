# frozen_string_literal: true

class AddDisableOverridingApproversPerMergeRequestIndices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DISABLE_OVERRIDING_APPROVERS_TRUE_INDEX_NAME = "idx_projects_id_created_at_disable_overriding_approvers_true"
  DISABLE_OVERRIDING_APPROVERS_FALSE_INDEX_NAME = "idx_projects_id_created_at_disable_overriding_approvers_false"

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:id, :created_at],
      where: "disable_overriding_approvers_per_merge_request = TRUE",
      name: DISABLE_OVERRIDING_APPROVERS_TRUE_INDEX_NAME

    add_concurrent_index :projects, [:id, :created_at],
      where: "(disable_overriding_approvers_per_merge_request = FALSE) OR (disable_overriding_approvers_per_merge_request IS NULL)",
      name: DISABLE_OVERRIDING_APPROVERS_FALSE_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, DISABLE_OVERRIDING_APPROVERS_TRUE_INDEX_NAME
    remove_concurrent_index_by_name :projects, DISABLE_OVERRIDING_APPROVERS_FALSE_INDEX_NAME
  end
end
