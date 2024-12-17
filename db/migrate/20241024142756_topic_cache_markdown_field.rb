# frozen_string_literal: true

class TopicCacheMarkdownField < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  def up
    with_lock_retries do
      add_column :topics, :cached_markdown_version, :integer, null: false, default: 0, if_not_exists: true
      add_column :topics, :description_html, :text, null: true, if_not_exists: true
    end

    add_text_limit :topics, :description_html, 50_000
  end

  def down
    with_lock_retries do
      remove_column :topics, :cached_markdown_version, if_exists: true
      remove_column :topics, :description_html, if_exists: true
    end
  end
end
