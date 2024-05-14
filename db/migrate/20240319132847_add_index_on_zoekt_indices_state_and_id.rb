# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexOnZoektIndicesStateAndId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.10'

  NEW_INDEX_NAME = 'index_zoekt_indices_on_state_and_id'
  OLD_INDEX_NAME = 'index_zoekt_indices_on_state'

  def up
    add_concurrent_index :zoekt_indices, %i[state id], name: NEW_INDEX_NAME, unique: true
    remove_concurrent_index_by_name :zoekt_indices, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :zoekt_indices, :state, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :zoekt_indices, NEW_INDEX_NAME
  end
end
