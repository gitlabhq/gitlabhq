# frozen_string_literal: true

class ChangeSearchRateLimitDefaultValues < Gitlab::Database::Migration[1.0]
  def change
    change_column_default :application_settings, :search_rate_limit, from: 30, to: 300
    change_column_default :application_settings, :search_rate_limit_unauthenticated, from: 10, to: 100
  end
end
