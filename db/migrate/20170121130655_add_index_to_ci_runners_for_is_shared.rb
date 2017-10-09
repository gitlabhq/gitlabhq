# rubocop:disable RemoveIndex
class AddIndexToCiRunnersForIsShared < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_runners, :is_shared
  end

  def down
    if index_exists?(:ci_runners, :is_shared)
      remove_index :ci_runners, :is_shared
    end
  end
end
