class RemoveCiVariablesProjectIdIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    if index_exists?(:ci_variables, :project_id)
      remove_concurrent_index(:ci_variables, :project_id)
    end
  end

  def down
    unless index_exists?(:ci_variables, :project_id)
      add_concurrent_index(:ci_variables, :project_id)
    end
  end
end
