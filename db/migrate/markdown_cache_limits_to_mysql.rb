class MarkdownCacheLimitsToMysql < ActiveRecord::Migration
  DOWNTIME = false

  def up
    return unless Gitlab::Database.mysql?

    change_column :snippets, :content_html, :text, limit: 2147483647
  end

  def down
    # no-op
  end
end
