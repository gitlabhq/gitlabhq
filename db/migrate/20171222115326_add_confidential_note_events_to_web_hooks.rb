class AddConfidentialNoteEventsToWebHooks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :web_hooks, :confidential_note_events, :boolean
  end

  def down
    remove_column :web_hooks, :confidential_note_events
  end
end
