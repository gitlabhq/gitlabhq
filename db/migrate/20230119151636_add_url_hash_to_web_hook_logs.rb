# frozen_string_literal: true

class AddUrlHashToWebHookLogs < Gitlab::Database::Migration[2.1]
  def change
    # limit is added in 20230119151940_add_text_limit_to_web_hook_logs_url_hash.rb
    add_column :web_hook_logs, :url_hash, :text # rubocop:disable Migration/AddLimitToTextColumns
  end
end
