class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.string :note
      t.string :noteable_commit_id
      t.string :noteable_type
      t.integer :noteable_id
      t.integer :author_id

      t.timestamps
    end
  end
end
