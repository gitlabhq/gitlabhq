# frozen_string_literal: true

class RemoveTempIndexForUserDetailsFields < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_idx_where_user_details_fields_filled'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :users, INDEX_NAME
  end

  def down
    # rubocop:disable Migration/PreventIndexCreation
    add_concurrent_index :users, :id, name: INDEX_NAME, where: <<~QUERY
      (COALESCE(linkedin, '') IS DISTINCT FROM '')
      OR (COALESCE(twitter, '') IS DISTINCT FROM '')
      OR (COALESCE(skype, '') IS DISTINCT FROM '')
      OR (COALESCE(website_url, '') IS DISTINCT FROM '')
      OR (COALESCE(location, '') IS DISTINCT FROM '')
      OR (COALESCE(organization, '') IS DISTINCT FROM '')
    QUERY
    # rubocop:enable Migration/PreventIndexCreation
  end
end
