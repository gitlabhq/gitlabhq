# frozen_string_literal: true

class ExtendIndexOnCiBuildsMetadata < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  OLD_INDEX = :index_ci_builds_metadata_on_build_id_and_interruptible
  NEW_INDEX = :index_ci_builds_metadata_on_build_id_and_id_and_interruptible

  TABLE = :ci_builds_metadata

  def up
    create_covering_index(TABLE, NEW_INDEX)

    remove_concurrent_index_by_name TABLE, OLD_INDEX
  end

  def down
    add_concurrent_index TABLE, :build_id, where: 'interruptible = true', name: OLD_INDEX

    remove_concurrent_index_by_name TABLE, NEW_INDEX
  end

  private

  def create_covering_index(table, name)
    return if index_exists_by_name?(table, name)

    disable_statement_timeout do
      execute <<~SQL
        CREATE INDEX CONCURRENTLY #{name}
        ON #{table} (build_id) INCLUDE (id)
        WHERE interruptible = true
      SQL
    end
  end
end
