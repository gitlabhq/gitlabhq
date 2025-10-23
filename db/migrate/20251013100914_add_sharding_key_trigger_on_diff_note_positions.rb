# frozen_string_literal: true

class AddShardingKeyTriggerOnDiffNotePositions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  FUNCTION_NAME = 'sync_sharding_key_with_notes_table'
  TRIGGER_NAME = 'set_sharding_key_for_diff_note_positions_on_insert_and_update'

  milestone '18.6'

  def up
    create_trigger(:diff_note_positions, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE INSERT OR UPDATE')
  end

  def down
    drop_trigger(:diff_note_positions, TRIGGER_NAME)
  end
end
