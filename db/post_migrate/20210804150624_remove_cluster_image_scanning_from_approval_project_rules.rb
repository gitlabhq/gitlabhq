# frozen_string_literal: true

class RemoveClusterImageScanningFromApprovalProjectRules < ActiveRecord::Migration[6.1]
  def up
    execute("update approval_project_rules set scanners = array_remove(scanners, 'cluster_image_scanning') where scanners @> '{cluster_image_scanning}'")
  end

  def down
    # nothing to do here
  end
end
