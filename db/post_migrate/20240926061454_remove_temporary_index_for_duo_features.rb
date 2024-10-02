# frozen_string_literal: true

class RemoveTemporaryIndexForDuoFeatures < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.5'

  TABLE_NAME = :namespace_settings
  INDEX_COLUMNS = %i[duo_features_enabled lock_duo_features_enabled]
  INDEX_NAME = :tmp_duo_features_enabled_index

  def up
    return unless index_exists?(TABLE_NAME, INDEX_COLUMNS, name: INDEX_NAME)

    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    return if index_exists?(TABLE_NAME, INDEX_COLUMNS, name: INDEX_NAME)

    add_concurrent_index(TABLE_NAME, INDEX_COLUMNS, name: INDEX_NAME)
  end
end
