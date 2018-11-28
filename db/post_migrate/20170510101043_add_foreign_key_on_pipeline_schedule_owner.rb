class AddForeignKeyOnPipelineScheduleOwner < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    execute <<-SQL
      UPDATE ci_pipeline_schedules
      SET owner_id = NULL
      WHERE NOT EXISTS (
        SELECT true
        FROM users
        WHERE ci_pipeline_schedules.owner_id = users.id
      )
    SQL

    add_concurrent_foreign_key(:ci_pipeline_schedules, :users, column: :owner_id, on_delete: on_delete)
  end

  def down
    remove_foreign_key(:ci_pipeline_schedules, column: :owner_id)
  end

  private

  def on_delete
    if Gitlab::Database.mysql?
      :nullify
    else
      'SET NULL'
    end
  end
end
