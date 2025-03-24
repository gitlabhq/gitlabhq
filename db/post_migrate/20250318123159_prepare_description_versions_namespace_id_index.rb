# frozen_string_literal: true

class PrepareDescriptionVersionsNamespaceIdIndex < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  INDEX_NAME = 'idx_description_versions_on_namespace_id'

  def up
    prepare_async_index :description_versions, :namespace_id, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Sharding keys are one of the exceptions
  end

  def down
    unprepare_async_index :description_versions, :namespace_id, name: INDEX_NAME
  end
end
