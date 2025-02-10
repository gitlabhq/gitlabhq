# frozen_string_literal: true

module IdeHelper
  # Overridden in EE
  def ide_data(project:, fork_info:, params:)
    base_data = {
      'use-new-web-ide' => use_new_web_ide?.to_s,
      'new-web-ide-help-page-path' => help_page_path('user/project/web_ide/_index.md'),
      'sign-in-path' => new_session_path(current_user),
      'sign-out-path' => destroy_user_session_path,
      'user-preferences-path' => profile_preferences_path
    }.merge(use_new_web_ide? ? new_ide_data(project: project) : legacy_ide_data(project: project))

    return base_data unless project

    base_data.merge(
      'fork-info' => fork_info&.to_json,
      'branch-name' => params[:branch],
      'file-path' => params[:path],
      'merge-request' => params[:merge_request_id]
    )
  end

  def show_web_ide_oauth_callback_mismatch_callout?
    return false unless ::WebIde::DefaultOauthApplication.feature_enabled?(current_user)

    callback_urls = ::WebIde::DefaultOauthApplication.oauth_application_callback_urls
    callback_url_domains = callback_urls.map { |url| URI.parse(url).origin }
    callback_url_domains.any? && callback_url_domains.exclude?(request.base_url)
  end

  def web_ide_oauth_application_id
    ::WebIde::DefaultOauthApplication.oauth_application_id
  end

  def use_new_web_ide?
    Feature.enabled?(:vscode_web_ide, current_user)
  end

  private

  def new_ide_fonts
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

  def new_ide_code_suggestions_data
    {}
  end

  def new_ide_oauth_data
    return {} unless ::WebIde::DefaultOauthApplication.feature_enabled?(current_user)
    return {} unless ::WebIde::DefaultOauthApplication.oauth_application

    client_id = ::WebIde::DefaultOauthApplication.oauth_application.uid
    callback_urls = ::WebIde::DefaultOauthApplication.oauth_application_callback_urls

    {
      'client-id' => client_id,
      'callback-urls' => callback_urls
    }
  end

  def new_ide_data(project:)
    extensions_gallery_settings = WebIde::ExtensionsMarketplace.webide_extensions_gallery_settings(user: current_user)
    settings_context_hash = WebIde::SettingsSync.settings_context_hash(
      extensions_gallery_settings: extensions_gallery_settings
    )

    {
      'project-path' => project&.path_with_namespace,
      'csp-nonce' => content_security_policy_nonce,
      'editor-font' => new_ide_fonts.to_json,
      'extensions-gallery-settings' => extensions_gallery_settings.to_json,
      'settings-context-hash' => settings_context_hash
    }.merge(new_ide_code_suggestions_data).merge(new_ide_oauth_data)
  end

  def legacy_ide_data(project:)
    {
      'empty-state-svg-path' => image_path('illustrations/empty-state/empty-variables-md.svg'),
      'no-changes-state-svg-path' => image_path('illustrations/status/status-nothing-sm.svg'),
      'committed-state-svg-path' => image_path('illustrations/rocket-launch-md.svg'),
      'pipelines-empty-state-svg-path': image_path('illustrations/empty-state/empty-pipeline-md.svg'),
      'switch-editor-svg-path': image_path('illustrations/rocket-launch-md.svg'),
      'ci-help-page-path' => help_page_path('ci/quick_start/_index.md'),
      'web-ide-help-page-path' => help_page_path('user/project/web_ide/_index.md'),
      'render-whitespace-in-code': current_user.render_whitespace_in_code.to_s,
      'default-branch' => project && project.default_branch,
      'project' => convert_to_project_entity_json(project),
      'preview-markdown-path' => project && preview_markdown_path(project),
      'web-terminal-svg-path' => image_path('illustrations/empty-state/empty-cloud-md.svg'),
      'web-terminal-help-path' => help_page_path('user/project/web_ide/_index.md'),
      'web-terminal-config-help-path' => help_page_path('user/project/web_ide/_index.md'),
      'web-terminal-runners-help-path' => help_page_path('user/project/web_ide/_index.md')
    }
  end

  def convert_to_project_entity_json(project)
    return unless project

    API::Entities::Project.represent(project, current_user: current_user).to_json
  end

  def has_dismissed_ide_environments_callout?
    current_user.dismissed_callout?(feature_name: 'web_ide_ci_environments_guidance')
  end
end
