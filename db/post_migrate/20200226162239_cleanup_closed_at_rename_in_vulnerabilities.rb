# frozen_string_literal: true

class CleanupClosedAtRenameInVulnerabilities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :vulnerabilities, :closed_at, :dismissed_at
  end

  def down
    undo_cleanup_concurrent_column_rename :vulnerabilities, :closed_at, :dismissed_at
  end
end
