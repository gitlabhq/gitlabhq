class AddIndexToEnvironmentNameForLike < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'index_environments_on_name_varchar_pattern_ops'

  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    unless index_exists?(:environments, :name, name: INDEX_NAME)
      execute("CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON environments (name varchar_pattern_ops);")
    end
  end

  def down
    return unless Gitlab::Database.postgresql?
    return unless index_exists?(:environments, :name, name: INDEX_NAME)

    remove_concurrent_index_by_name(:environments, INDEX_NAME)
  end
end
