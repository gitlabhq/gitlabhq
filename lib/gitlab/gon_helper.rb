module Gitlab
  module GonHelper
    def add_gon_variables
      gon.api_version            = API::API.version
      gon.default_avatar_url     = URI::join(Gitlab.config.gitlab.url, ActionController::Base.helpers.image_path('no_avatar.png')).to_s
      gon.max_file_size          = current_application_settings.max_attachment_size
      gon.relative_url_root      = Gitlab.config.gitlab.relative_url_root
      gon.shortcuts_path         = help_page_path('shortcuts')
      gon.user_color_scheme      = Gitlab::ColorSchemes.for_user(current_user).css_class
      gon.award_menu_url         = emojis_path

      if current_user
        gon.current_user_id = current_user.id
      end
    end
  end
end
