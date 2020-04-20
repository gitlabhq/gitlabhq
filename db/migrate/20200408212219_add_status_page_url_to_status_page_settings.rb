# frozen_string_literal: true

class AddStatusPageUrlToStatusPageSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :status_page_settings, :status_page_url, :text
    add_text_limit :status_page_settings, :status_page_url, 1024
  end

  def down
    remove_column :status_page_settings, :status_page_url
  end
end
