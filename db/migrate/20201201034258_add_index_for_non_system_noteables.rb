# frozen_string_literal: true

class AddIndexForNonSystemNoteables < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  LEGACY_INDEX_NAME = "index_notes_on_noteable_id_and_noteable_type"
  NEW_INDEX_NAME = "index_notes_on_noteable_id_and_noteable_type_and_system"

  def up
    add_concurrent_index :notes, [:noteable_id, :noteable_type, :system], name: NEW_INDEX_NAME

    remove_concurrent_index_by_name :notes, LEGACY_INDEX_NAME
  end

  def down
    add_concurrent_index :notes, [:noteable_id, :noteable_type], name: LEGACY_INDEX_NAME

    remove_concurrent_index_by_name :notes, NEW_INDEX_NAME
  end
end
