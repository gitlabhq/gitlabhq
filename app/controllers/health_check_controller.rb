class HealthCheckController < HealthCheck::HealthCheckController
  include RequiresWhitelistedMonitoringClient
end
