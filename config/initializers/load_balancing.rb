# frozen_string_literal: true

ActiveRecord::Base.singleton_class.attr_accessor :load_balancing_proxy

Gitlab::Database.main.disable_prepared_statements

Gitlab::Application.configure do |config|
  config.middleware.use(Gitlab::Database::LoadBalancing::RackMiddleware)
end

# This hijacks the "connection" method to ensure both
# `ActiveRecord::Base.connection` and all models use the same load
# balancing proxy.
ActiveRecord::Base.singleton_class.prepend(Gitlab::Database::LoadBalancing::ActiveRecordProxy)

# The load balancer needs to be configured immediately, and re-configured after
# forking. This ensures queries that run before forking use the load balancer,
# and queries running after a fork don't run into any errors when using dead
# database connections.
#
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63485 for more
# information.
setup = proc do
  lb = Gitlab::Database::LoadBalancing::LoadBalancer.new(
    Gitlab::Database::LoadBalancing.configuration,
    primary_only: !Gitlab::Database::LoadBalancing.enable_replicas?
  )

  ActiveRecord::Base.load_balancing_proxy =
    Gitlab::Database::LoadBalancing::ConnectionProxy.new(lb)

  # Populate service discovery immediately if it is configured
  Gitlab::Database::LoadBalancing.perform_service_discovery
end

setup.call

# Database queries may be run before we fork, so we must set up the load
# balancer as early as possible. When we do fork, we need to make sure all the
# hosts are disconnected.
Gitlab::Cluster::LifecycleEvents.on_before_fork do
  # When forking, we don't want to wait until the connections aren't in use any
  # more, as this could delay the boot cycle.
  Gitlab::Database::LoadBalancing.proxy.load_balancer.disconnect!(timeout: 0)
end

# Service discovery only needs to run in the worker processes, as the main one
# won't be running many (if any) database queries.
Gitlab::Cluster::LifecycleEvents.on_worker_start do
  setup.call
  Gitlab::Database::LoadBalancing.start_service_discovery
end
