# frozen_string_literal: true

class Terraform::ServicesController < ApplicationController
  skip_before_action :authenticate_user!

  feature_category :package_registry

  def index
    render json: { 'modules.v1' => "/api/#{::API::API.version}/packages/terraform/modules/v1/" }
  end
end
