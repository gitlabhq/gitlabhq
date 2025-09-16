# frozen_string_literal: true

class Import::UrlController < ApplicationController
  feature_category :importers
  urgency :low

  before_action only: :new do
    push_frontend_feature_flag(:import_by_url_new_page, current_user)
  end

  def new
    render_404 unless Feature.enabled?(:import_by_url_new_page, current_user)
  end

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
