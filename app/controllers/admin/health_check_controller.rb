class Admin::HealthCheckController < Admin::ApplicationController
  def show
    begin
      @errors = HealthCheck::Utils.process_checks('standard')
    rescue => e
      @errors = e.message.blank? ? e.class.to_s : e.message.to_s
    end
  end
end
