# frozen_string_literal: true

class AddSidekiqLimitsToApplicationSettings < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction! # needed for now to avoid subtransactions

  def up
    with_lock_retries do
      add_column :application_settings, :sidekiq_job_limiter_mode, :smallint, default: 1, null: false
      add_column :application_settings, :sidekiq_job_limiter_compression_threshold_bytes, :integer, default: 100_000, null: false
      add_column :application_settings, :sidekiq_job_limiter_limit_bytes, :integer, default: 0, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :sidekiq_job_limiter_mode
      remove_column :application_settings, :sidekiq_job_limiter_compression_threshold_bytes
      remove_column :application_settings, :sidekiq_job_limiter_limit_bytes
    end
  end
end
