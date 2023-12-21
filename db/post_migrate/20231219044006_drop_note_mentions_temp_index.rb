# frozen_string_literal: true

class DropNoteMentionsTempIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  INDEX_NAME = 'note_mentions_temp_index'

  def up
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end

  def down
    add_concurrent_index :notes, [:id, :noteable_type], where: "note ~~ '%@%'::text", name: INDEX_NAME
  end
end
