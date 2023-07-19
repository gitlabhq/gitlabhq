# frozen_string_literal: true

class AddFkOnMlModelVersionsToMlModels < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:ml_model_versions, :ml_models, column: :model_id, on_delete: :cascade)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:ml_model_versions, column: :model_id, on_delete: :cascade)
    end
  end
end
