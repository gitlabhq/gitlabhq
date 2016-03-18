class AddConfidentialToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :confidential, :boolean, default: false
    add_index :issues, :confidential
  end
end
