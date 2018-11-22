class AddAutoCanceledByIdForeignKeyToPipeline < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    on_delete =
      if Gitlab::Database.mysql?
        :nullify
      else
        'SET NULL'
      end

    add_concurrent_foreign_key :ci_pipelines, :ci_pipelines, column: :auto_canceled_by_id, on_delete: on_delete
  end

  def down
    remove_foreign_key :ci_pipelines, column: :auto_canceled_by_id
  end
end
