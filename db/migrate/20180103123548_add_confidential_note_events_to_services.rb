class AddConfidentialNoteEventsToServices < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :services, :confidential_note_events, :boolean
    change_column_default :services, :confidential_note_events, true
  end

  def down
    remove_column :services, :confidential_note_events
  end
end
