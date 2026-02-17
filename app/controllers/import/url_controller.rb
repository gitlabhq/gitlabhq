# frozen_string_literal: true

class Import::UrlController < ApplicationController
  feature_category :importers
  urgency :low

  before_action only: :new do
    push_frontend_feature_flag(:import_by_url_new_page, current_user)
  end

  def new
    render_404 unless Feature.enabled?(:import_by_url_new_page, current_user)

    return unless namespace_id.present?

    namespace = Namespace.find_by_id(namespace_id)
    @namespace = namespace if namespace && can?(current_user, :import_projects, namespace)
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

  def namespace_id
    params.permit(:namespace_id)[:namespace_id]
  end
end
