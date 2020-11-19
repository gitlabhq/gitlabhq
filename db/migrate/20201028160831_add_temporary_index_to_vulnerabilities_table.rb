# frozen_string_literal: true

class AddTemporaryIndexToVulnerabilitiesTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'temporary_index_vulnerabilities_on_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerabilities, :id, where: "state = 2 AND (dismissed_at IS NULL OR dismissed_by_id IS NULL)", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerabilities, INDEX_NAME
  end
end
