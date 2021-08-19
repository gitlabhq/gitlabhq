# frozen_string_literal: true

class AddScannersColumnToApprovalProjectRules < ActiveRecord::Migration[6.1]
  def up
    add_column :approval_project_rules, :scanners, :text, array: true
  end

  def down
    remove_column :approval_project_rules, :scanners
  end
end
