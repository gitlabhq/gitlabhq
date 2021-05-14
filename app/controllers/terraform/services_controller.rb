# frozen_string_literal: true

class Terraform::ServicesController < ApplicationController
  skip_before_action :authenticate_user!

  feature_category :infrastructure_as_code

  def index
    render json: { 'modules.v1' => "/api/#{::API::API.version}/packages/terraform/modules/v1/" }
  end
end
