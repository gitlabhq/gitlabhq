# frozen_string_literal: true

class HealthCheckController < HealthCheck::HealthCheckController
  include RequiresAllowlistedMonitoringClient
end
