# frozen_string_literal: true

class AddIndexOnDynamicAndIdToOauthApplications < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_oauth_applications_dynamic_and_id'

  def up
    add_concurrent_index :oauth_applications, [:dynamic, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :oauth_applications, INDEX_NAME
  end
end
