# frozen_string_literal: true

class Import::UrlController < ApplicationController
  feature_category :importers
  urgency :low

  def new
    if namespace_id.present?
      namespace = Namespace.find_by_id(namespace_id)
      @namespace = namespace if namespace && can?(current_user, :import_projects, namespace)

      render_404 unless @namespace
    else
      unless can?(current_user, :import_projects, current_user.namespace)
        access_denied!(s_('ProjectImportByURL|You do not have permission to import projects.'))
      end
    end
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
