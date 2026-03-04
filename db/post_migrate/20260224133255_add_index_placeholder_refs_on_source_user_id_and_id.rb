# frozen_string_literal: true

class AddIndexPlaceholderRefsOnSourceUserIdAndId < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  TABLE_NAME = :import_source_user_placeholder_references
  COLUMNS = [:source_user_id, :id]
  INDEX_NAME = 'index_import_source_user_placeholder_refs_on_source_user_id_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/591
    add_concurrent_index TABLE_NAME, COLUMNS, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
