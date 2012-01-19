class AddIndexes < ActiveRecord::Migration
  def change
    add_index :issues, :project_id
    add_index :merge_requests, :project_id
    add_index :notes, :noteable_id
    add_index :notes, :noteable_type
  end

end
