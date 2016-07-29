class AddWeightToIssue < ActiveRecord::Migration
  def change
    add_column :issues, :weight, :integer
  end
end
