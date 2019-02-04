# frozen_string_literal: true

class HealthCheckController < HealthCheck::HealthCheckController
  include RequiresWhitelistedMonitoringClient
end
