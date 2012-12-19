class IndicesForNotes < ActiveRecord::Migration
  def change
    add_index :notes, :commit_id
    add_index :notes, [:project_id, :noteable_type]
  end
end
