# frozen_string_literal: true

class AddTextLimitToWebHookLogsUrlHash < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :web_hook_logs, :url_hash, 44, validate: false
  end

  def down
    remove_text_limit :web_hook_logs, :url_hash
  end
end
