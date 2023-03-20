# frozen_string_literal: true

class AddProjectsApiRateLimitUnauthenticatedToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :projects_api_rate_limit_unauthenticated, :integer, default: 400, null: false
  end
end
