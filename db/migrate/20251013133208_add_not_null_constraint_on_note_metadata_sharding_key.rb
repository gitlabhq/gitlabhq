# frozen_string_literal: true

class AddNotNullConstraintOnNoteMetadataShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_not_null_constraint :note_metadata, :namespace_id, validate: false
  end

  def down
    remove_not_null_constraint :note_metadata, :namespace_id
  end
end
