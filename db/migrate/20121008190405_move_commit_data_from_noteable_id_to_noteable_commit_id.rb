class MoveCommitDataFromNoteableIdToNoteableCommitId < ActiveRecord::Migration
  def up
    execute "UPDATE notes SET noteable_commit_id = noteable_id WHERE noteable_type = 'Commit'"
    execute "UPDATE notes SET noteable_id = null WHERE noteable_type = 'Commit'"
  end

  def down
    execute "UPDATE notes SET noteable_id = noteable_commit_id WHERE noteable_type = 'Commit'"
  end
end
