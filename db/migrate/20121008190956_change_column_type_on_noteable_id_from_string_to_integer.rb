class ChangeColumnTypeOnNoteableIdFromStringToInteger < ActiveRecord::Migration
  def up
    add_column :notes, :temp, :integer
    Note.reset_column_information
    Note.find_each do |note|
      if note.noteable_type != 'Commit'
        note.temp = note.noteable_id
        note.save
      end
    end

    remove_column :notes, :noteable_id
    add_column :notes, :noteable_id, :integer
    Note.reset_column_information
    Note.find_each do |note|
      if note.noteable_type != 'Commit'
        note.temp = note.noteable_id
        note.save
      end
    end

    remove_column :notes, :temp
  end

  def down
    change_column :notes, :noteable_id, :string, limit: 255
  end
end
