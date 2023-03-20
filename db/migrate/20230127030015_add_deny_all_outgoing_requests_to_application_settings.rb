# frozen_string_literal: true

class AddDenyAllOutgoingRequestsToApplicationSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :application_settings, :deny_all_requests_except_allowed, :boolean, default: false, null: false
  end
end
