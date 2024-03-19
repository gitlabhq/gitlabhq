# frozen_string_literal: true

class AddTextLimitToWebHooksCustomWebhookTemplate < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.10'

  def up
    add_text_limit :web_hooks, :custom_webhook_template, 4096
  end

  def down
    remove_text_limit :web_hooks, :custom_webhook_template
  end
end
