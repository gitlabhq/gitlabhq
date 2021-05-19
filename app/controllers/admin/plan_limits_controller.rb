# frozen_string_literal: true

class Admin::PlanLimitsController < Admin::ApplicationController
  include InternalRedirect

  before_action :set_plan_limits

  feature_category :not_owned

  def create
    redirect_path = referer_path(request) || general_admin_application_settings_path

    respond_to do |format|
      if @plan_limits.update(plan_limits_params)
        format.json { head :ok }
        format.html { redirect_to redirect_path, notice: _('Application limits saved successfully') }
      else
        format.json { head :bad_request }
        format.html { render_update_error }
      end
    end
  end

  private

  def set_plan_limits
    @plan_limits = Plan.find(plan_limits_params[:plan_id]).actual_limits
  end

  def plan_limits_params
    params.require(:plan_limits).permit(%i[
      plan_id
      conan_max_file_size
      maven_max_file_size
      npm_max_file_size
      nuget_max_file_size
      pypi_max_file_size
      terraform_module_max_file_size
      generic_packages_max_file_size
    ])
  end
end
