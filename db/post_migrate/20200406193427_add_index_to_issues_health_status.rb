# frozen_string_literal: true

class AddIndexToIssuesHealthStatus < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'idx_issues_on_health_status_not_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :issues,
      :health_status,
      where: 'health_status IS NOT NULL',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:issues, INDEX_NAME)
  end
end
