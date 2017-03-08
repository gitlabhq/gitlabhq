class Admin::HealthCheckController < Admin::ApplicationController
  def show
    checks = ['standard']
    checks << 'geo' if Gitlab::Geo.secondary?

    @errors = HealthCheck::Utils.process_checks(checks)
  end
end
