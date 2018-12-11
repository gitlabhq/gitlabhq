class AddForeignKeyToCiVariables < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    execute <<~SQL
      DELETE FROM ci_variables
      WHERE NOT EXISTS (
        SELECT true
        FROM projects
        WHERE projects.id = ci_variables.project_id
      )
    SQL

    add_concurrent_foreign_key(:ci_variables, :projects, column: :project_id)
  end

  def down
    remove_foreign_key(:ci_variables, column: :project_id)
  end
end
