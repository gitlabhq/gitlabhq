# frozen_string_literal: true

class SetIssueIdForAllVersions < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    execute('UPDATE design_management_versions as versions SET issue_id = (
      SELECT design_management_designs.issue_id
        FROM design_management_designs
        INNER JOIN design_management_designs_versions ON design_management_designs.id = design_management_designs_versions.design_id
        WHERE design_management_designs_versions.version_id = versions.id
        LIMIT 1
    )')
  end

  def down
    # no-op
  end
end
