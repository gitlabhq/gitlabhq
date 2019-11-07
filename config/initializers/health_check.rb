HealthCheck.setup do |config|
  config.standard_checks = %w(database migrations cache)
  config.full_checks = %w(database migrations cache)

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
