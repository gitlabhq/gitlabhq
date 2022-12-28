# frozen_string_literal: true

class IndexCiRunnersOnCreatorId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_runners_on_creator_id_where_creator_id_not_null'

  def up
    add_concurrent_index :ci_runners, :creator_id, where: 'creator_id IS NOT NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_runners, INDEX_NAME
  end
end
