# frozen_string_literal: true

class RenameClosedAtToDismissedAtInVulnerabilities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :vulnerabilities, :closed_at, :dismissed_at
  end

  def down
    undo_rename_column_concurrently :vulnerabilities, :closed_at, :dismissed_at
  end
end
