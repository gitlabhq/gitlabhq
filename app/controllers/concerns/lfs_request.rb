# frozen_string_literal: true

# This concern assumes:
# - a `#container` accessor
# - a `#project` accessor
# - a `#user` accessor
# - a `#deploy_token` accessor
# - a `#authentication_result` accessor
# - a `#can?(object, action, subject)` method
# - a `#ci?` method
# - a `#download_request?` method
# - a `#upload_request?` method
# - a `#has_authentication_ability?(ability)` method
module LfsRequest
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  CONTENT_TYPE = 'application/vnd.git-lfs+json'

  included do
    before_action :require_lfs_enabled!
    before_action :lfs_check_access!
  end

  private

  def require_lfs_enabled!
    return if Gitlab.config.lfs.enabled

    render(
      json: {
        message: _('Git LFS is not enabled on this GitLab server, contact your admin.'),
        documentation_url: help_url
      },
      content_type: CONTENT_TYPE,
      status: :not_implemented
    )
  end

  def lfs_check_access!
    return render_lfs_not_found unless container&.lfs_enabled?
    return if download_request? && lfs_download_access?
    return if upload_request? && lfs_upload_access?

    # Only return a 403 response if the user has download access permission,
    # otherwise return a 404 to avoid exposing the existence of the container.
    if lfs_download_access?
      lfs_forbidden!
    else
      render_lfs_not_found
    end
  end

  def lfs_forbidden!
    render_lfs_forbidden
  end

  def render_lfs_forbidden
    render(
      json: {
        message: _('Access forbidden. Check your access level.'),
        documentation_url: help_url
      },
      content_type: CONTENT_TYPE,
      status: :forbidden
    )
  end

  def render_lfs_not_found
    render(
      json: {
        message: _('Not found.'),
        documentation_url: help_url
      },
      content_type: CONTENT_TYPE,
      status: :not_found
    )
  end

  def lfs_download_access?
    ci? || lfs_deploy_token? || user_can_download_code? || build_can_download_code? || deploy_token_can_download_code?
  end
  strong_memoize_attr :lfs_download_access?

  def deploy_token_can_download_code?
    deploy_token.present? &&
      deploy_token.has_access_to?(project) &&
      deploy_token.read_repository?
  end

  def lfs_upload_access?
    return false unless has_authentication_ability?(:push_code)
    return false if limit_exceeded?

    lfs_deploy_token? ||
      can?(user, :push_code, project) ||
      can?(deploy_token, :push_code, project) ||
      any_branch_allows_collaboration?
  end
  strong_memoize_attr :lfs_upload_access?

  def any_branch_allows_collaboration?
    project.merge_requests_allowing_push_to_user(user).any?
  end

  def lfs_deploy_token?
    authentication_result.lfs_deploy_token?(project)
  end

  def user_can_download_code?
    has_authentication_ability?(:download_code) && can?(user, :download_code, project)
  end

  def build_can_download_code?
    has_authentication_ability?(:build_download_code) && can?(user, :build_download_code, project)
  end

  def objects
    @objects ||= (params[:objects] || []).to_a
  end

  def objects_oids
    objects.map { |o| o['oid'].to_s }
  end

  def has_authentication_ability?(capability)
    (authentication_abilities || []).include?(capability)
  end

  # Overridden in EE
  def limit_exceeded?
    false
  end
end

LfsRequest.prepend_mod_with('LfsRequest')
