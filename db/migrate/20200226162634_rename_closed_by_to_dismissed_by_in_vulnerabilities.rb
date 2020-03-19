# frozen_string_literal: true

class RenameClosedByToDismissedByInVulnerabilities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :vulnerabilities, :closed_by_id, :dismissed_by_id
  end

  def down
    undo_rename_column_concurrently :vulnerabilities, :closed_by_id, :dismissed_by_id
  end
end
