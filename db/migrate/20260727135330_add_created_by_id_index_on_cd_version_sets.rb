# frozen_string_literal: true

class AddCreatedByIdIndexOnCdVersionSets < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_cd_version_sets_on_created_by_id'

  disable_ddl_transaction!

  milestone '19.3'

  def up
    add_concurrent_index :cd_version_sets, :created_by_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :cd_version_sets, INDEX_NAME
  end
end
