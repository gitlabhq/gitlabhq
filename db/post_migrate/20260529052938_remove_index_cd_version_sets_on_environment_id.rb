# frozen_string_literal: true

class RemoveIndexCdVersionSetsOnEnvironmentId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  INDEX_NAME = 'index_cd_version_sets_on_environment_id'

  def up
    remove_concurrent_index_by_name :cd_version_sets, INDEX_NAME
  end

  def down
    add_concurrent_index :cd_version_sets, :environment_id, name: INDEX_NAME
  end
end
