class AddNoteableCommitIdFieldToNotesTable < ActiveRecord::Migration
  def change
    add_column :notes, :noteable_commit_id, :string, limit: 255
  end
end
