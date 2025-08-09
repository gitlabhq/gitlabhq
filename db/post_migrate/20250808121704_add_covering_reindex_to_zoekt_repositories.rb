# frozen_string_literal: true

class AddCoveringReindexToZoektRepositories < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  OLD_INDEX_NAME = :idx_zoekt_repositories_on_zoekt_index_id_and_state
  NEW_INDEX_NAME = :idx_zoekt_repositories_on_zoekt_index_id_and_state_with_schema
  TABLE_NAME = :zoekt_repositories

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[zoekt_index_id state],
      name: NEW_INDEX_NAME,
      include: %i[schema_version]
    )
    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, %i[zoekt_index_id state], name: OLD_INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
