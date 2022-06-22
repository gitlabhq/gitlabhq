# frozen_string_literal: true

class AddMaxRepositoryDownloadsLimitToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :max_number_of_repository_downloads,
      :smallint,
      default: 0,
      null: false

    add_column :application_settings, :max_number_of_repository_downloads_within_time_period,
      :integer,
      default: 0,
      null: false
  end
end
