class AddSystemToNotes < ActiveRecord::Migration
  class Note < ActiveRecord::Base
  end

  def up
    add_column :notes, :system, :boolean, default: false, null: false

    Note.reset_column_information
    Note.update_all(system: false)
    Note.where("note like '_status changed to%'").update_all(system: true)
  end

  def down
    remove_column :notes, :system
  end
end
