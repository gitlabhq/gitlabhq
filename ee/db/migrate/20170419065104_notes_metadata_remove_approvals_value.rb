class NotesMetadataRemoveApprovalsValue < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute("DELETE FROM system_note_metadata WHERE action = 'approvals'")
  end
end
