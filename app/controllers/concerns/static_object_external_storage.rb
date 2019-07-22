# frozen_string_literal: true

module StaticObjectExternalStorage
  extend ActiveSupport::Concern

  included do
    include ApplicationHelper
  end

  def redirect_to_external_storage
    return if external_storage_request?

    redirect_to external_storage_url_or_path(request.fullpath, project)
  end

  def external_storage_request?
    header_token = request.headers['X-Gitlab-External-Storage-Token']
    return false unless header_token.present?

    external_storage_token = Gitlab::CurrentSettings.static_objects_external_storage_auth_token
    ActiveSupport::SecurityUtils.secure_compare(header_token, external_storage_token) ||
      raise(Gitlab::Access::AccessDeniedError)
  end
end
