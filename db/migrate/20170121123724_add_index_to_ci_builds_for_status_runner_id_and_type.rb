# rubocop:disable RemoveIndex
class AddIndexToCiBuildsForStatusRunnerIdAndType < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds, [:status, :type, :runner_id]
  end

  def down
    if index_exists?(:ci_builds, [:status, :type, :runner_id])
      remove_index :ci_builds, column: [:status, :type, :runner_id]
    end
  end
end
