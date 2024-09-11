# frozen_string_literal: true

class RemoveNotNullConstraintOnProjectIdWikiPageMeta < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  def up
    change_column_null :wiki_page_meta, :project_id, true
  end

  def down
    change_column_null :wiki_page_meta, :project_id, false
  end
end
