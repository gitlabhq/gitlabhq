# frozen_string_literal: true

Gitlab::Application.configure do |config|
  config.middleware.use(Gitlab::Database::LoadBalancing::RackMiddleware)

  # We need re-rerun the setup when code reloads in development
  config.reloader.to_prepare do
    if Gitlab.dev_or_test_env?
      Gitlab::Database::LoadBalancing.base_models.each do |model|
        Gitlab::Database::LoadBalancing::Setup.new(model).setup
      end
    end
  end
end

Gitlab::Database::LoadBalancing.base_models.each do |model|
  # The load balancer needs to be configured immediately, and re-configured
  # after forking. This ensures queries that run before forking use the load
  # balancer, and queries running after a fork don't run into any errors when
  # using dead database connections.
  #
  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63485 for more
  # information.
  Gitlab::Database::LoadBalancing::Setup.new(model).setup

  # Database queries may be run before we fork, so we must set up the load
  # balancer as early as possible. When we do fork, we need to make sure all the
  # hosts are disconnected.
  Gitlab::Cluster::LifecycleEvents.on_before_fork do
    # When forking, we don't want to wait until the connections aren't in use
    # any more, as this could delay the boot cycle.
    model.load_balancer.disconnect!(timeout: 0)
  end

  # Service discovery only needs to run in the worker processes, as the main one
  # won't be running many (if any) database queries.
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    Gitlab::Database::LoadBalancing::Setup
      .new(model, start_service_discovery: true)
      .setup
  end
end

ActiveSupport.run_load_hooks(:gitlab_db_load_balancer)
