# rubocop:disable all
class AddDefaultBranchProtectionSetting < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :default_branch_protection, :integer, :default => 2
  end
end
