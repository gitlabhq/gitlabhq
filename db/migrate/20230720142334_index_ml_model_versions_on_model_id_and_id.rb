# frozen_string_literal: true

class IndexMlModelVersionsOnModelIdAndId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'unique_ml_model_versions_on_model_id_and_id'

  def up
    add_concurrent_index :ml_model_versions, [:model_id, :id], name: INDEX_NAME, order: { id: :desc }
  end

  def down
    remove_concurrent_index_by_name :ml_model_versions, INDEX_NAME
  end
end
