# frozen_string_literal: true

HealthCheck.setup do |config|
  config.standard_checks = %w[database all-migrations cache]
  config.full_checks = %w[database all-migrations cache]

  config.add_custom_check('all-migrations') do
    # We use a custom check (rather than `ActiveRecord::Migration.check_pending_migrations`)
    # so we can exclude post-deployment migrations, which are on the runtime migration path
    # by default but which the running application does not depend on.
    #
    Gitlab::Database::Migrations::PendingMigrationsCheck.check!
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
