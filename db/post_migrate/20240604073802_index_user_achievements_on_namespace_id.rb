# frozen_string_literal: true

class IndexUserAchievementsOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_user_achievements_on_namespace_id'

  def up
    add_concurrent_index :user_achievements, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :user_achievements, INDEX_NAME
  end
end
