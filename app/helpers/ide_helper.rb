# frozen_string_literal: true

module IdeHelper
  # Overridden in EE
  def ide_data(project:, fork_info:, params:)
    base_data = {
      'new-web-ide-help-page-path' => help_page_path('user/project/web_ide/_index.md'),
      'sign-in-path' => new_session_path(current_user),
      'sign-out-path' => destroy_user_session_path,
      'user-preferences-path' => profile_preferences_path
    }.merge(extend_ide_data(project: project))

    return base_data unless project

    base_data.merge(
      'fork-info' => fork_info&.to_json,
      'branch-name' => params[:branch],
      'file-path' => params[:path],
      'merge-request' => params[:merge_request_id]
    )
  end

  def show_web_ide_oauth_callback_mismatch_callout?
    callback_urls = ::WebIde::DefaultOauthApplication.oauth_application_callback_urls
    callback_url_domains = callback_urls.map { |url| URI.parse(url).origin }
    callback_url_domains.any? && callback_url_domains.exclude?(request.base_url)
  end

  def web_ide_oauth_application_id
    ::WebIde::DefaultOauthApplication.oauth_application_id
  end

  private

  def ide_fonts
    {
      fallback_font_family: 'monospace',
      font_faces: [{
        family: 'GitLab Mono',
        display: 'block',
        src: [{
          url: font_url('gitlab-mono/GitLabMono.woff2'),
          format: 'woff2'
        }]
      }, {
        family: 'GitLab Mono',
        display: 'block',
        style: 'italic',
        src: [{
          url: font_url('gitlab-mono/GitLabMono-Italic.woff2'),
          format: 'woff2'
        }]
      }]
    }
  end

  def ide_code_suggestions_data
    {}
  end

  def ide_oauth_data
    return {} unless ::WebIde::DefaultOauthApplication.oauth_application

    client_id = ::WebIde::DefaultOauthApplication.oauth_application.uid
    callback_urls = ::WebIde::DefaultOauthApplication.oauth_application_callback_urls

    {
      'client-id' => client_id,
      'callback-urls' => callback_urls
    }
  end

  def extend_ide_data(project:)
    extension_marketplace_settings = WebIde::ExtensionMarketplace.webide_extension_marketplace_settings(
      user: current_user
    )
    settings_context_hash = WebIde::SettingsSync.settings_context_hash(
      extension_marketplace_settings: extension_marketplace_settings
    )

    {
      'project-path' => project&.path_with_namespace,
      'csp-nonce' => content_security_policy_nonce,
      'editor-font' => ide_fonts.to_json,
      'extension-marketplace-settings' => extension_marketplace_settings.to_json,
      'settings-context-hash' => settings_context_hash,
      'extension-host-domain' => WebIde::ExtensionMarketplace.extension_host_domain,
      'extension-host-domain-changed' => WebIde::ExtensionMarketplace.extension_host_domain_changed?.to_s
    }.merge(ide_code_suggestions_data).merge(ide_oauth_data)
  end

  def has_dismissed_ide_environments_callout?
    current_user.dismissed_callout?(feature_name: 'web_ide_ci_environments_guidance')
  end
end
