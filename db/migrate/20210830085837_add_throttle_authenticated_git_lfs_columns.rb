# frozen_string_literal: true

class AddThrottleAuthenticatedGitLfsColumns < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :application_settings, :throttle_authenticated_git_lfs_requests_per_period, :integer, default: 1000, null: false
      add_column :application_settings, :throttle_authenticated_git_lfs_period_in_seconds, :integer, default: 60, null: false
      add_column :application_settings, :throttle_authenticated_git_lfs_enabled, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :throttle_authenticated_git_lfs_requests_per_period
      remove_column :application_settings, :throttle_authenticated_git_lfs_period_in_seconds
      remove_column :application_settings, :throttle_authenticated_git_lfs_enabled, :boolean
    end
  end
end
