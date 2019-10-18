# frozen_string_literal: true

class AddIndexToSytemNoteMetadataDescriptionVersionId < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :system_note_metadata, :description_version_id, unique: true, where: 'description_version_id IS NOT NULL'
    add_concurrent_foreign_key :system_note_metadata, :description_versions, column: :description_version_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :system_note_metadata, column: :description_version_id
    remove_concurrent_index :system_note_metadata, :description_version_id
  end
end
