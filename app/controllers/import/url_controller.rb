# frozen_string_literal: true

class Import::UrlController < ApplicationController
  feature_category :importers
  urgency :low

  def validate
    result = Import::ValidateRemoteGitEndpointService.new(validate_params).execute
    if result.success?
      render json: { success: true }
    else
      render json: { success: false, message: result.message }
    end
  end

  private

  def validate_params
    params.permit(:user, :password, :url)
  end
end
