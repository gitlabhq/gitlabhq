# frozen_string_literal: true

class RemoveNotNullConstraintForSecurityScanSucceeded < Gitlab::Database::Migration[1.0]
  def up
    change_column_null :analytics_devops_adoption_snapshots, :security_scan_succeeded, true
  end

  def down
    # There may now be nulls in the table, so we cannot re-add the constraint here.
  end
end
