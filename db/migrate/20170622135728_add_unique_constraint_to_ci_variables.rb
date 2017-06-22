class AddUniqueConstraintToCiVariables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless index_exists?(:ci_variables, columns)
      add_concurrent_index(:ci_variables, columns, unique: true)
    end
  end

  def down
    if index_exists?(:ci_variables, columns) && Gitlab::Database.postgresql?
      remove_concurrent_index(:ci_variables, columns)
    end
  end

  def columns
    @columns ||= [:project_id, :key, :environment_scope]
  end
end
