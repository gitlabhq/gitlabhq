# frozen_string_literal: true

class AddMultiColumnNotNullConstraintToWikiPageSlugs < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:wiki_page_slugs, :project_id, :namespace_id)
  end

  def down
    remove_multi_column_not_null_constraint(:wiki_page_slugs, :project_id, :namespace_id)
  end
end
