# frozen_string_literal: true

class IndexSnippetStatisticsOnSnippetOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_snippet_statistics_on_snippet_organization_id'

  def up
    add_concurrent_index :snippet_statistics, :snippet_organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :snippet_statistics, INDEX_NAME
  end
end
