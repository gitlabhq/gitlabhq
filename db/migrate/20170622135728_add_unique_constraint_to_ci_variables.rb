class AddUniqueConstraintToCiVariables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless this_index_exists?
      add_concurrent_index(:ci_variables, columns, name: index_name, unique: true)
    end
  end

  def down
    if this_index_exists?
      if Gitlab::Database.mysql? && !index_exists?(:ci_variables, :project_id)
        # Need to add this index for MySQL project_id foreign key constraint
        add_concurrent_index(:ci_variables, :project_id)
      end

      remove_concurrent_index(:ci_variables, columns, name: index_name)
    end
  end

  private

  def this_index_exists?
    index_exists?(:ci_variables, columns, name: index_name)
  end

  def columns
    @columns ||= [:project_id, :key, :environment_scope]
  end

  def index_name
    'index_ci_variables_on_project_id_and_key_and_environment_scope'
  end
end
