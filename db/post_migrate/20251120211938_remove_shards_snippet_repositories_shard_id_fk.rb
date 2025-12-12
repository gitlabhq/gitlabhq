# frozen_string_literal: true

class RemoveShardsSnippetRepositoriesShardIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_rails_f21f899728"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:snippet_repositories, :shards,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:snippet_repositories, :shards,
      name: FOREIGN_KEY_NAME, column: :shard_id,
      target_column: :id, on_delete: :restrict)
  end
end
