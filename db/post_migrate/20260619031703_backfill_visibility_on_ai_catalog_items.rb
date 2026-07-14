# frozen_string_literal: true

class BackfillVisibilityOnAiCatalogItems < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '19.2'

  VISIBILITY_PUBLIC = 2

  def up
    update_column_in_batches(:ai_catalog_items, :visibility, VISIBILITY_PUBLIC) do |table, query|
      query.where(table[:public].eq(true))
    end
  end

  def down
    update_column_in_batches(:ai_catalog_items, :visibility, 0) do |table, query|
      query.where(table[:visibility].eq(VISIBILITY_PUBLIC))
    end
  end
end
