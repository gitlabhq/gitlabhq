# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveCommasFromWeightNote < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  def up
    ActiveRecord::Base.connection.execute(<<-EOQ)
      UPDATE notes
      SET notes.note = SUBSTRING(notes.note, 1, LEN(notes.note) - 1)
      FROM system_note_metadata 
      WHERE system_note_metadata.note_id = notes.id AND notes.system AND system_note_metadata.action = 'weight' AND notes.note LIKE '%,'
    EOQ
  end

  def down
    old_notes = Note.where("note LIKE 'changed weight to%'")

    old_notes.find_each do |note|
      note.update_column(:note, note.note.concat(','))
    end
  end
end
