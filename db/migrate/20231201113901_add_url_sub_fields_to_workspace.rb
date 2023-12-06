# frozen_string_literal: true

class AddUrlSubFieldsToWorkspace < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  def up
    add_column :workspaces, :url_prefix, :text, if_not_exists: true
    add_column :workspaces, :url_domain, :text, if_not_exists: true
    add_column :workspaces, :url_query_string, :text, if_not_exists: true

    add_text_limit :workspaces, :url_prefix, 256
    add_text_limit :workspaces, :url_domain, 256
    add_text_limit :workspaces, :url_query_string, 256
  end

  def down
    remove_column :workspaces, :url_prefix, if_exists: true
    remove_column :workspaces, :url_domain, if_exists: true
    remove_column :workspaces, :url_query_string, if_exists: true
  end
end
