# frozen_string_literal: true

class Admin::HealthCheckController < Admin::ApplicationController
  feature_category :not_owned

  def show
    @errors = HealthCheck::Utils.process_checks(checks)
  end

  private

  def checks
    ['standard']
  end
end

Admin::HealthCheckController.prepend_if_ee('EE::Admin::HealthCheckController')
