# frozen_string_literal: true

class PrepareAsyncIndexPlaceholderRefsOnSourceUserIdAndId < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  TABLE_NAME = :import_source_user_placeholder_references
  COLUMNS = [:source_user_id, :id]
  INDEX_NAME = 'index_import_source_user_placeholder_refs_on_source_user_id_id'

  def up
    prepare_async_index TABLE_NAME, COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, COLUMNS, name: INDEX_NAME
  end
end
