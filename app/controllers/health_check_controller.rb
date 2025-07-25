# frozen_string_literal: true

class HealthCheckController < HealthCheck::HealthCheckController
  helper ViteHelper

  include RequiresAllowlistedMonitoringClient
end
