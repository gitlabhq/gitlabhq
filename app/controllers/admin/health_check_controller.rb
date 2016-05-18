class Admin::HealthCheckController < Admin::ApplicationController
  def show
    @errors = HealthCheck::Utils.process_checks('standard')
  end
end
