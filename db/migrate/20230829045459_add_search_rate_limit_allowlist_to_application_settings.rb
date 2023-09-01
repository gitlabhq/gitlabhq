# frozen_string_literal: true

class AddSearchRateLimitAllowlistToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :search_rate_limit_allowlist, :text, array: true, default: [], null: false
  end
end
