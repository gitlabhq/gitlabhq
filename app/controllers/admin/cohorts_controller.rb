# frozen_string_literal: true

class Admin::CohortsController < Admin::ApplicationController
  feature_category :devops_reports

  # Backwards compatibility. Remove it and routing in 14.0
  # @see https://gitlab.com/gitlab-org/gitlab/-/issues/299303
  def index
    redirect_to cohorts_admin_users_path
  end
end
