# frozen_string_literal: true

class RemoveDevopsAdoptionSecurityScanSucceededColumn < Gitlab::Database::Migration[2.0]
  def up
    remove_column :analytics_devops_adoption_snapshots, :security_scan_succeeded
  end

  def down
    add_column :analytics_devops_adoption_snapshots, :security_scan_succeeded, :boolean
  end
end
