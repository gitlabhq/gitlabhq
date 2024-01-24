# frozen_string_literal: true

class AddIndexToMlModelVersionsOnCreatedAtOnModelId < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ml_model_versions_on_created_at_on_model_id'

  def up
    add_concurrent_index :ml_model_versions, [:model_id, :created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ml_model_versions, name: INDEX_NAME
  end
end
