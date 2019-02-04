class AddUpdatedByToIssuablesAndNotes < ActiveRecord::Migration[4.2]
  def change
    add_column :notes, :updated_by_id, :integer
    add_column :issues, :updated_by_id, :integer
    add_column :merge_requests, :updated_by_id, :integer
  end
end
