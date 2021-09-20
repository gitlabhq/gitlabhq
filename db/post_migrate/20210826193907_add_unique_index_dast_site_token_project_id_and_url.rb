# frozen_string_literal: true

class AddUniqueIndexDastSiteTokenProjectIdAndUrl < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_dast_site_token_on_project_id_and_url'

  def up
    add_concurrent_index :dast_site_tokens, [:project_id, :url], name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :dast_site_tokens, name: INDEX_NAME
  end
end
