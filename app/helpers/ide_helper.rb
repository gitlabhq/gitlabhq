# frozen_string_literal: true

module IdeHelper
  # Overridden in EE
  def ide_data(project:, fork_info:, params:)
    base_data = {
      'use-new-web-ide' => use_new_web_ide?.to_s,
      'new-web-ide-help-page-path' => help_page_path('user/project/web_ide/index', anchor: 'vscode-reimplementation'),
      'sign-in-path' => new_session_path(current_user),
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
    return {} unless ::Gitlab::WebIde::DefaultOauthApplication.feature_enabled?(current_user)
    return {} unless ::Gitlab::WebIde::DefaultOauthApplication.oauth_application

    client_id = ::Gitlab::WebIde::DefaultOauthApplication.oauth_application.uid
    callback_url = ::Gitlab::WebIde::DefaultOauthApplication.oauth_callback_url

    {
      'client-id' => client_id,
      'callback-url' => callback_url
    }
  end

  def new_ide_data(project:)
    {
      'project-path' => project&.path_with_namespace,
      'csp-nonce' => content_security_policy_nonce,
      # We will replace these placeholders in the FE
      'ide-remote-path' => ide_remote_path(remote_host: ':remote_host', remote_path: ':remote_path'),
      'editor-font' => new_ide_fonts.to_json
    }.merge(new_ide_code_suggestions_data).merge(new_ide_oauth_data)
  end

  def legacy_ide_data(project:)
    {
      'empty-state-svg-path' => image_path('illustrations/multi_file_editor_empty.svg'),
      'no-changes-state-svg-path' => image_path('illustrations/multi-editor_no_changes_empty.svg'),
      'committed-state-svg-path' => image_path('illustrations/rocket-launch-md.svg'),
      'pipelines-empty-state-svg-path': image_path('illustrations/empty-state/empty-pipeline-md.svg'),
      'switch-editor-svg-path': image_path('illustrations/rocket-launch-md.svg'),
      'promotion-svg-path': image_path('illustrations/web-ide_promotion.svg'),
      'ci-help-page-path' => help_page_path('ci/quick_start/index'),
      'web-ide-help-page-path' => help_page_path('user/project/web_ide/index'),
      'render-whitespace-in-code': current_user.render_whitespace_in_code.to_s,
      'default-branch' => project && project.default_branch,
      'project' => convert_to_project_entity_json(project),
      'preview-markdown-path' => project && preview_markdown_path(project),
      'web-terminal-svg-path' => image_path('illustrations/web-ide_promotion.svg'),
      'web-terminal-help-path' => help_page_path('user/project/web_ide/index', anchor: 'interactive-web-terminals-for-the-web-ide'),
      'web-terminal-config-help-path' => help_page_path('user/project/web_ide/index', anchor: 'web-ide-configuration-file'),
      'web-terminal-runners-help-path' => help_page_path('user/project/web_ide/index', anchor: 'runner-configuration')
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
