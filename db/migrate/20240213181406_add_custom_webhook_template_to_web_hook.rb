# frozen_string_literal: true

class AddCustomWebhookTemplateToWebHook < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.10'

  def change
    # rubocop:disable Migration/AddLimitToTextColumns -- limit is added in 20240213181407
    add_column :web_hooks, :custom_webhook_template, :text, null: true
    # rubocop:enable Migration/AddLimitToTextColumns
  end
end
