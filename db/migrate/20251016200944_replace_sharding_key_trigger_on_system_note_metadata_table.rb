# frozen_string_literal: true

class ReplaceShardingKeyTriggerOnSystemNoteMetadataTable < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  NEW_FUNCTION_NAME = 'sync_sharding_key_with_notes_table'
  OLD_FUNCTION_NAME = 'get_sharding_key_from_notes_table'
  OLD_TRIGGER_NAME = 'set_sharding_key_for_system_note_metadata_on_insert'
  NEW_TRIGGER_NAME = 'set_namespace_for_system_note_metadata_on_insert'

  milestone '18.6'

  def up
    create_trigger(:system_note_metadata, NEW_TRIGGER_NAME, NEW_FUNCTION_NAME, fires: 'BEFORE INSERT')
    drop_trigger(:system_note_metadata, OLD_TRIGGER_NAME)
  end

  def down
    create_trigger(:system_note_metadata, OLD_TRIGGER_NAME, OLD_FUNCTION_NAME, fires: 'BEFORE INSERT')
    drop_trigger(:system_note_metadata, NEW_TRIGGER_NAME)
  end
end
