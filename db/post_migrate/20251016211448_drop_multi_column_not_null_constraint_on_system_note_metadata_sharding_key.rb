# frozen_string_literal: true

class DropMultiColumnNotNullConstraintOnSystemNoteMetadataShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    remove_multi_column_not_null_constraint :system_note_metadata, :namespace_id, :organization_id
  end

  def down
    add_multi_column_not_null_constraint :system_note_metadata,
      :namespace_id,
      :organization_id,
      validate: false
  end
end
