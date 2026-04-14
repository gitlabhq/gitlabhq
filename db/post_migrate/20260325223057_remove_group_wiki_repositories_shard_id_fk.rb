# frozen_string_literal: true

class RemoveGroupWikiRepositoriesShardIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_rails_19755e374b"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:group_wiki_repositories, :shards,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:group_wiki_repositories, :shards,
      name: FOREIGN_KEY_NAME, column: :shard_id,
      on_delete: :restrict)
  end
end
