# rubocop:disable all
class AddConfidentialToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :confidential, :boolean, default: false
    add_index :issues, :confidential
  end
end
