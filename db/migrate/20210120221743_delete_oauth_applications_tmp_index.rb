# frozen_string_literal: true

class DeleteOauthApplicationsTmpIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'tmp_index_oauth_applications_on_id_where_trusted'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :oauth_applications, INDEX_NAME
  end

  def down
    add_concurrent_index :oauth_applications, :id, where: 'trusted = true', name: INDEX_NAME
  end
end
