# frozen_string_literal: true

class Projects::GoogleCloud::DeploymentsController < Projects::GoogleCloud::BaseController
  before_action :validate_gcp_token!

  def cloud_run
    render json: "Placeholder"
  end

  def cloud_storage
    render json: "Placeholder"
  end
end
