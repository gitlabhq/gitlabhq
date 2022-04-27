# frozen_string_literal: true

class Projects::PipelinesSettingsController < Projects::ApplicationController
  before_action :authorize_admin_pipeline!

  feature_category :continuous_integration
  urgency :low

  def show
    redirect_to project_settings_ci_cd_path(@project, params: params.to_unsafe_h)
  end
end
