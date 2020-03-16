# frozen_string_literal: true

class CleanupClosedByRenameInVulnerabilities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :vulnerabilities, :closed_by_id, :dismissed_by_id
  end

  def down
    undo_cleanup_concurrent_column_rename :vulnerabilities, :closed_by_id, :dismissed_by_id
  end
end
