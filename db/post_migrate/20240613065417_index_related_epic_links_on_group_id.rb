# frozen_string_literal: true

class IndexRelatedEpicLinksOnGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_related_epic_links_on_group_id'

  def up
    add_concurrent_index :related_epic_links, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :related_epic_links, INDEX_NAME
  end
end
