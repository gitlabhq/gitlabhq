# frozen_string_literal: true

class AddResolvedOnDefaultBranchIntoVulnerabilitiesTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_table :vulnerabilities do |t|
      t.boolean :resolved_on_default_branch, default: false, null: false
    end
  end
end
