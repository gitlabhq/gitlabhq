# frozen_string_literal: true

class AddBioHtmlToUserDetails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      # Note: bio_html is calculated from bio, the bio column is already constrained
      add_column :user_details, :bio_html, :text # rubocop:disable Migration/AddLimitToTextColumns
      add_column :user_details, :cached_markdown_version, :integer
    end
  end

  def down
    with_lock_retries do
      remove_column :user_details, :bio_html
      remove_column :user_details, :cached_markdown_version
    end
  end
end
