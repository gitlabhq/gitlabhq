# frozen_string_literal: true

class RemoveMlModelsProjectIdPlainForeignKey < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  FK_NAME = 'fk_rails_51e87f7c50'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ml_models, :projects, name: FK_NAME)
    end
  end

  def down
    add_concurrent_foreign_key :ml_models, :projects, name: FK_NAME, column: :project_id, on_delete: nil
  end
end
