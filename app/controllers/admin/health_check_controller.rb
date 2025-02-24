# frozen_string_literal: true

class Admin::HealthCheckController < Admin::ApplicationController
  feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

  authorize! :read_admin_health_check, only: [:show]

  def show
    @errors = HealthCheck::Utils.process_checks(checks)
  end

  private

  def checks
    ['standard']
  end
end

Admin::HealthCheckController.prepend_mod_with('Admin::HealthCheckController')
