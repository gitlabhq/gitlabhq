class AddAuthorIdToEvent < ActiveRecord::Migration
  def change
    add_column :events, :author_id, :integer, :null => true
  end
end
