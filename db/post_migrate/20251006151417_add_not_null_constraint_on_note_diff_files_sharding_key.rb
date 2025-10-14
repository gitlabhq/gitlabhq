# frozen_string_literal: true

class AddNotNullConstraintOnNoteDiffFilesShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_not_null_constraint :note_diff_files, :namespace_id, validate: false
  end

  def down
    remove_not_null_constraint :note_diff_files, :namespace_id
  end
end
