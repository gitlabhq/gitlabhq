# rubocop:disable RemoveIndex
class AddIndexToProjectAuthorizations < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless index_exists?(:project_authorizations, :project_id)
      add_concurrent_index(:project_authorizations, :project_id)
    end
  end

  def down
    remove_index(:project_authorizations, :project_id) if
      Gitlab::Database.postgresql?
  end
end
