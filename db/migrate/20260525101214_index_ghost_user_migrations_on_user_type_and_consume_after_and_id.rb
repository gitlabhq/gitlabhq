# frozen_string_literal: true

class IndexGhostUserMigrationsOnUserTypeAndConsumeAfterAndId < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ghost_user_migrations_on_user_type_consume_after_id'

  def up
    add_concurrent_index(
      :ghost_user_migrations,
      [:user_type, :consume_after, :id],
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :ghost_user_migrations, INDEX_NAME
  end
end
