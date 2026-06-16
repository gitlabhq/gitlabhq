# frozen_string_literal: true

class IndexGhostUserMigrationsOnConsumeAfterAndIdNonHuman < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ghost_user_migrations_on_consume_after_id_non_human'

  def up
    add_concurrent_index(
      :ghost_user_migrations,
      [:consume_after, :id],
      name: INDEX_NAME,
      where: 'user_type != 0'
    )
  end

  def down
    remove_concurrent_index_by_name :ghost_user_migrations, INDEX_NAME
  end
end
