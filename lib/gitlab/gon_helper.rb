# rubocop:disable Metrics/AbcSize

module Gitlab
  module GonHelper
    include WebpackHelper
    include Gitlab::CurrentSettings

    def add_gon_variables
      gon.api_version            = 'v4'
      gon.default_avatar_url     = URI.join(Gitlab.config.gitlab.url, ActionController::Base.helpers.image_path('no_avatar.png')).to_s
      gon.max_file_size          = current_application_settings.max_attachment_size
      gon.asset_host             = ActionController::Base.asset_host
      gon.webpack_public_path    = webpack_public_path
      gon.relative_url_root      = Gitlab.config.gitlab.relative_url_root
      gon.shortcuts_path         = help_page_path('shortcuts')
      gon.user_color_scheme      = Gitlab::ColorSchemes.for_user(current_user).css_class
      gon.katex_css_url          = ActionController::Base.helpers.asset_path('katex.css')
      gon.katex_js_url           = ActionController::Base.helpers.asset_path('katex.js')
      gon.sentry_dsn             = current_application_settings.clientside_sentry_dsn if current_application_settings.clientside_sentry_enabled
      gon.gitlab_url             = Gitlab.config.gitlab.url
      gon.revision               = Gitlab::REVISION
      gon.gitlab_logo            = ActionController::Base.helpers.asset_path('gitlab_logo.png')
      gon.sprite_icons           = ActionController::Base.helpers.asset_path('icons.svg')

      if current_user
        gon.current_user_id = current_user.id
        gon.current_username = current_user.username
        gon.current_user_fullname = current_user.name
        gon.current_user_avatar_url = current_user.avatar_url
      end
    end
  end
end
