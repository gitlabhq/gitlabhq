class MoveNoteableCommitToOwnField < ActiveRecord::Migration
  def up
    add_column :notes, :commit_id, :string, null: true
    add_column :notes, :new_noteable_id, :integer, null: true
    Note.where(noteable_type: 'Commit').update_all('commit_id = noteable_id')

    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      Note.where("noteable_type != 'Commit'").update_all('new_noteable_id = CAST (noteable_id AS INTEGER)')
    else
      Note.where("noteable_type != 'Commit'").update_all('new_noteable_id = noteable_id')
    end

    remove_column :notes, :noteable_id
    rename_column :notes, :new_noteable_id, :noteable_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
