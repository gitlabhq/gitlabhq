class HealthCheckController < HealthCheck::HealthCheckController
  include RequiresHealthToken
end
