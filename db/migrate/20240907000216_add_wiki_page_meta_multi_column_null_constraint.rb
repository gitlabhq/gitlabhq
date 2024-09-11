# frozen_string_literal: true

class AddWikiPageMetaMultiColumnNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:wiki_page_meta, :namespace_id, :project_id)
  end

  def down
    remove_multi_column_not_null_constraint(:wiki_page_meta, :namespace_id, :project_id)
  end
end
