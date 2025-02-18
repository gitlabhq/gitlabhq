# frozen_string_literal: true

class CreateSystemHooks < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    create_table :system_hooks do |t|
      t.timestamps null: true # rubocop:disable Migration/Timestamps -- Needs to match web_hooks table
      t.datetime_with_timezone :disabled_until

      t.integer :recent_failures, limit: 2, default: 0, null: false
      t.integer :backoff_count, limit: 2, default: 0, null: false
      t.integer :branch_filter_strategy, limit: 2, default: 0, null: false

      t.boolean :push_events, default: true, null: false
      t.boolean :merge_requests_events, default: false, null: false
      t.boolean :tag_push_events, default: false
      t.boolean :enable_ssl_verification, default: true
      t.boolean :repository_update_events, default: false, null: false

      t.text :push_events_branch_filter, limit: 5000
      t.text :name, limit: 255
      t.text :description, limit: 2048
      t.text :custom_webhook_template, limit: 4096

      t.binary :encrypted_token
      t.binary :encrypted_token_iv
      t.binary :encrypted_url
      t.binary :encrypted_url_iv

      t.binary :encrypted_url_variables
      t.binary :encrypted_url_variables_iv
      t.binary :encrypted_custom_headers
      t.binary :encrypted_custom_headers_iv
    end
  end
end
