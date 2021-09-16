# frozen_string_literal: true

class AddJobsPerStagePageSizeToApplicationSettings < Gitlab::Database::Migration[1.0]
  def change
    add_column :application_settings, :jobs_per_stage_page_size, :integer, default: 200, null: false
  end
end
