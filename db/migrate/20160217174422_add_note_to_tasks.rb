class AddNoteToTasks < ActiveRecord::Migration[4.2]
  def change
    add_reference :tasks, :note, index: true
  end
end
