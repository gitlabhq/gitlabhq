# frozen_string_literal: true

class AddAFullUniqueIndexOnIssuableResourceLinks < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_unique_issuable_resource_links_on_issue_id_and_link'

  disable_ddl_transaction!

  DEPENDENT_BATCHED_BACKGROUND_MIGRATIONS = [
    20240908225334,
    20240911101712,
    20241111055711
  ]

  milestone '18.1'

  def up
    add_concurrent_index(
      :issuable_resource_links,
      %i[issue_id link],
      name: INDEX_NAME,
      unique: true
    )
  end

  def down
    remove_concurrent_index_by_name(:issuable_resource_links, INDEX_NAME)
  end
end
