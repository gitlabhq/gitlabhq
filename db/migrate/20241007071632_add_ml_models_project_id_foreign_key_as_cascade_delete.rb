# frozen_string_literal: true

class AddMlModelsProjectIdForeignKeyAsCascadeDelete < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  FK_NAME = 'fk_51e87f7c50_new'

  def up
    add_concurrent_foreign_key :ml_models, :projects, name: FK_NAME, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:ml_models, :projects, name: FK_NAME)
    end
  end
end
