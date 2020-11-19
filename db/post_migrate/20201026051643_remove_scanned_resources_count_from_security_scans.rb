# frozen_string_literal: true

class RemoveScannedResourcesCountFromSecurityScans < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    remove_column :security_scans, :scanned_resources_count
  end

  def down
    add_column :security_scans, :scanned_resources_count, :integer
  end
end
