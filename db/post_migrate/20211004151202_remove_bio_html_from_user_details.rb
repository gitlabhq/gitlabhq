# frozen_string_literal: true

class RemoveBioHtmlFromUserDetails < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    remove_column :user_details, :bio_html, :text, null: true
    remove_column :user_details, :cached_markdown_version, :integer, null: true
  end
end
