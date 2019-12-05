# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize

module Gitlab
  module GonHelper
    include WebpackHelper

    def add_gon_variables
      gon.api_version            = 'v4'
      gon.default_avatar_url     = default_avatar_url
      gon.max_file_size          = Gitlab::CurrentSettings.max_attachment_size
      gon.asset_host             = ActionController::Base.asset_host
      gon.webpack_public_path    = webpack_public_path
      gon.relative_url_root      = Gitlab.config.gitlab.relative_url_root
      gon.shortcuts_path         = Gitlab::Routing.url_helpers.help_page_path('shortcuts')
      gon.user_color_scheme      = Gitlab::ColorSchemes.for_user(current_user).css_class

      if Gitlab.config.sentry.enabled
        gon.sentry_dsn           = Gitlab.config.sentry.clientside_dsn
        gon.sentry_environment   = Gitlab.config.sentry.environment
      end

      gon.gitlab_url             = Gitlab.config.gitlab.url
      gon.revision               = Gitlab.revision
      gon.gitlab_logo            = ActionController::Base.helpers.asset_path('gitlab_logo.png')
      gon.sprite_icons           = IconsHelper.sprite_icon_path
      gon.sprite_file_icons      = IconsHelper.sprite_file_icons_path
      gon.emoji_sprites_css_path = ActionController::Base.helpers.stylesheet_path('emoji_sprites')
      gon.test_env               = Rails.env.test?
      gon.suggested_label_colors = LabelsHelper.suggested_colors
      gon.first_day_of_week      = current_user&.first_day_of_week || Gitlab::CurrentSettings.first_day_of_week
      gon.ee                     = Gitlab.ee?

      if current_user
        gon.current_user_id = current_user.id
        gon.current_username = current_user.username
        gon.current_user_fullname = current_user.name
        gon.current_user_avatar_url = current_user.avatar_url
      end

      # Initialize gon.features with any flags that should be
      # made globally available to the frontend
      push_frontend_feature_flag(:suppress_ajax_navigation_errors, default_enabled: true)
      push_frontend_feature_flag(:snippets_vue, default_enabled: false)
    end

    # Exposes the state of a feature flag to the frontend code.
    #
    # name - The name of the feature flag, e.g. `my_feature`.
    # args - Any additional arguments to pass to `Feature.enabled?`. This allows
    #        you to check if a flag is enabled for a particular user.
    def push_frontend_feature_flag(name, *args)
      var_name = name.to_s.camelize(:lower)
      enabled = Feature.enabled?(name, *args)

      # Here the `true` argument signals gon that the value should be merged
      # into any existing ones, instead of overwriting them. This allows you to
      # use this method to push multiple feature flags.
      gon.push({ features: { var_name => enabled } }, true)
    end

    def default_avatar_url
      # We can't use ActionController::Base.helpers.image_url because it
      # doesn't return an actual URL because request is nil for some reason.
      #
      # We also can't use Gitlab::Utils.append_path because the image path
      # may be an absolute URL.
      URI.join(Gitlab.config.gitlab.url,
               ActionController::Base.helpers.image_path('no_avatar.png')).to_s
    end
  end
end
