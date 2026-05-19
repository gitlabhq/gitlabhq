# frozen_string_literal: true

class RemoveIndexNotesOnIdWhereConfidential < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  INDEX_NAME = 'index_notes_on_id_where_confidential'

  def up
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end

  def down
    add_concurrent_index :notes, :id, where: 'confidential = true', name: INDEX_NAME
  end
end
