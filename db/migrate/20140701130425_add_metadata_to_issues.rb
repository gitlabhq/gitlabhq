class AddMetadataToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :metadata, :string
  end
end
