class AddDefaultBranchProtectionSetting < ActiveRecord::Migration
  def change
    add_column :application_settings, :default_branch_protection, :integer, :default => 2
  end
end
