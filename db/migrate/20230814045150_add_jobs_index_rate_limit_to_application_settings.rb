# frozen_string_literal: true

class AddJobsIndexRateLimitToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :project_jobs_api_rate_limit, :integer, default: 600, null: false
  end
end
