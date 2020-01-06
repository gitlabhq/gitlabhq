# frozen_string_literal: true

module IdeHelper
  def ide_data
    {
      "empty-state-svg-path" => image_path('illustrations/multi_file_editor_empty.svg'),
      "no-changes-state-svg-path" => image_path('illustrations/multi-editor_no_changes_empty.svg'),
      "committed-state-svg-path" => image_path('illustrations/multi-editor_all_changes_committed_empty.svg'),
      "pipelines-empty-state-svg-path": image_path('illustrations/pipelines_empty.svg'),
      "promotion-svg-path": image_path('illustrations/web-ide_promotion.svg'),
      "ci-help-page-path" => help_page_path('ci/quick_start/README'),
      "web-ide-help-page-path" => help_page_path('user/project/web_ide/index.html'),
      "clientside-preview-enabled": Gitlab::CurrentSettings.current_application_settings.web_ide_clientside_preview_enabled.to_s,
      "render-whitespace-in-code": current_user.render_whitespace_in_code.to_s
    }
  end
end
