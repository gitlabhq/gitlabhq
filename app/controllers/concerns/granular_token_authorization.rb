# frozen_string_literal: true

module GranularTokenAuthorization
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  # Default granular permission per sessionless format; formats absent here are not enforced.
  GRANULAR_FORMAT_PERMISSIONS = {
    rss: :read_work_item,
    ics: :read_work_item,
    archive: :download_code,
    download: :read_release,
    design: :read_design,
    editor_extension: :create_editor_telemetry
  }.freeze

  def authorize_granular_token!(request_format, permission: nil)
    permission ||= GRANULAR_FORMAT_PERMISSIONS[request_format]
    return unless permission

    token = sessionless_access_token
    return unless token

    deny_granular_token! unless granular_scopes_authorized?(token, permission, granular_token_boundary)
  end

  private

  # `Current.token_info` is set by the auth finders on success; nil for sessions,
  # feed tokens, and invalid tokens.
  def sessionless_access_token
    info = ::Current.token_info
    return unless info

    case info[:token_type]
    when ::PersonalAccessToken.name
      ::PersonalAccessToken.find_by_id(info[:token_id])
    when ::OauthAccessToken.name
      ::OauthAccessToken.find_by_id(info[:token_id])
    end
  end

  def granular_scopes_authorized?(token, permission, subject)
    ::Authz::Tokens::AuthorizeGranularScopesService.new(
      boundaries: ::Authz::Boundary.for(subject),
      permissions: permission,
      token: token
    ).execute.success?
  end

  # A project boundary also authorizes group- and root-scoped tokens via ancestry.
  def granular_token_boundary
    if respond_to?(:project, true) && project
      project
    elsif respond_to?(:group, true) && group
      group
    else
      ::Authz::GranularScope::Access::USER
    end
  end

  # Overridable for controllers without render_404 (e.g. EventForwardController).
  def deny_granular_token!
    render_404
  end

  def granular_access_token
    token = authentication_result_token
    return unless token.try(:granular?)

    token
  end
  strong_memoize_attr :granular_access_token

  def access_token_authorized?(subject, permission)
    token = authentication_result_token
    return true unless token

    granular_scopes_authorized?(token, permission, subject)
  end

  def authentication_result_token
    authentication_result&.access_token
  end
end
