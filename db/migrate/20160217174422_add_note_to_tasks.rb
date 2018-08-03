class AddNoteToTasks < ActiveRecord::Migration
  def change
    add_reference :tasks, :note, index: true
  end
end
