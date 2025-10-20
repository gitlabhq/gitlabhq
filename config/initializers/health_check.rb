# frozen_string_literal: true

HealthCheck.setup do |config|
  config.standard_checks = %w[database all_migrations cache]
  config.full_checks = %w[database all_migrations cache]

  # In Rails 7.1+, `check_pending!` was deprecated in favor of `check_all_pending!`
  # which loops through all DB connection pools.
  # This isn't supported natively by the gem so we implement a custom check for this.
  # See https://github.com/Purple-Devs/health_check/pull/148
  config.add_custom_check('all_migrations') do
    # `check_all_pending!` mutates the `ActiveRecord::Base` connection pool so we use
    # `#check_pending_migrations` because it uses a separate `ActiveRecord::PendingMigrationConnection`
    ActiveRecord::Migration.check_pending_migrations
    ''
  rescue ActiveRecord::PendingMigrationError => ex
    ex.message
  end

  Gitlab.ee do
    config.add_custom_check('geo') do
      Gitlab::Geo::HealthCheck.new.perform_checks
    end
  end
end

Gitlab::Cluster::LifecycleEvents.on_before_fork do
  Gitlab::HealthChecks::MasterCheck.register_master
end

Gitlab::Cluster::LifecycleEvents.on_before_blackout_period do
  Gitlab::HealthChecks::MasterCheck.finish_master
end

Gitlab::Cluster::LifecycleEvents.on_worker_start do
  Gitlab::HealthChecks::MasterCheck.register_worker
end
