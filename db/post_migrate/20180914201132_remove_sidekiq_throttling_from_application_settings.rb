# frozen_string_literal: true
# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveSidekiqThrottlingFromApplicationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_column :application_settings, :sidekiq_throttling_enabled, :boolean, default: false
    remove_column :application_settings, :sidekiq_throttling_queues, :string
    remove_column :application_settings, :sidekiq_throttling_factor, :decimal

    Rails.cache.delete("ApplicationSetting:#{Gitlab::VERSION}:#{Rails.version}")
  end
end
