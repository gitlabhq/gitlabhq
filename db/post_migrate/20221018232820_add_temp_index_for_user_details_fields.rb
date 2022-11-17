# frozen_string_literal: true

class AddTempIndexForUserDetailsFields < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_idx_where_user_details_fields_filled'

  disable_ddl_transaction!

  def up
    add_concurrent_index :users, :id, name: INDEX_NAME, where: <<~QUERY
      (COALESCE(linkedin, '') IS DISTINCT FROM '')
      OR (COALESCE(twitter, '') IS DISTINCT FROM '')
      OR (COALESCE(skype, '') IS DISTINCT FROM '')
      OR (COALESCE(website_url, '') IS DISTINCT FROM '')
      OR (COALESCE(location, '') IS DISTINCT FROM '')
      OR (COALESCE(organization, '') IS DISTINCT FROM '')
    QUERY
  end

  def down
    remove_concurrent_index_by_name :users, INDEX_NAME
  end
end
