# frozen_string_literal: true

class DropIndexMlModelVersionsOnModelId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ml_model_versions_on_model_id'

  def up
    remove_concurrent_index_by_name :ml_model_versions, INDEX_NAME
  end

  def down
    add_concurrent_index :ml_model_versions, :model_id, name: INDEX_NAME
  end
end
