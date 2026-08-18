# frozen_string_literal: true

class Admin::JobsController < Admin::ApplicationController
  BUILDS_PER_PAGE = 30

  feature_category :continuous_integration
  urgency :low

  before_action do
    push_frontend_feature_flag(:admin_jobs_filter_runner_type, type: :ops)
  end

  def index; end

  def cancel_all
    Ci::Build.running_or_pending.each(&:cancel)

    redirect_to admin_jobs_path, status: :see_other
  end
end

Admin::JobsController.prepend_mod
