# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize

module Gitlab
  module GonHelper
    include WebpackHelper

    def add_gon_variables
      gon.api_version             = 'v4'
      gon.default_avatar_url      = default_avatar_url
      gon.max_file_size           = Gitlab::CurrentSettings.max_attachment_size
      gon.asset_host              = ActionController::Base.asset_host
      gon.webpack_public_path     = webpack_public_path
      gon.relative_url_root       = Gitlab.config.gitlab.relative_url_root
      gon.user_color_scheme       = Gitlab::ColorSchemes.for_user(current_user).css_class
      gon.markdown_surround_selection = current_user&.markdown_surround_selection

      if Gitlab.config.sentry.enabled
        gon.sentry_dsn           = Gitlab.config.sentry.clientside_dsn
        gon.sentry_environment   = Gitlab.config.sentry.environment
      end

      gon.gitlab_url             = Gitlab.config.gitlab.url
      gon.revision               = Gitlab.revision
      gon.feature_category       = Gitlab::ApplicationContext.current_context_attribute(:feature_category).presence
      gon.gitlab_logo            = ActionController::Base.helpers.asset_path('gitlab_logo.png')
      gon.sprite_icons           = IconsHelper.sprite_icon_path
      gon.sprite_file_icons      = IconsHelper.sprite_file_icons_path
      gon.emoji_sprites_css_path = ActionController::Base.helpers.stylesheet_path('emoji_sprites')
      gon.select2_css_path       = ActionController::Base.helpers.stylesheet_path('lazy_bundles/select2.css')
      gon.test_env               = Rails.env.test?
      gon.disable_animations     = Gitlab.config.gitlab['disable_animations']
      gon.suggested_label_colors = LabelsHelper.suggested_colors
      gon.first_day_of_week      = current_user&.first_day_of_week || Gitlab::CurrentSettings.first_day_of_week
      gon.time_display_relative  = true
      gon.ee                     = Gitlab.ee?
      gon.dot_com                = Gitlab.com?

      if current_user
        gon.current_user_id = current_user.id
        gon.current_username = current_user.username
        gon.current_user_fullname = current_user.name
        gon.current_user_avatar_url = current_user.avatar_url
        gon.time_display_relative = current_user.time_display_relative
      end

      # Initialize gon.features with any flags that should be
      # made globally available to the frontend
      push_frontend_feature_flag(:snippets_binary_blob, default_enabled: false)
      push_frontend_feature_flag(:usage_data_api, type: :ops, default_enabled: :yaml)
      push_frontend_feature_flag(:security_auto_fix, default_enabled: false)
      push_frontend_feature_flag(:improved_emoji_picker, default_enabled: :yaml)
    end

    # Exposes the state of a feature flag to the frontend code.
    #
    # name - The name of the feature flag, e.g. `my_feature`.
    # args - Any additional arguments to pass to `Feature.enabled?`. This allows
    #        you to check if a flag is enabled for a particular user.
    def push_frontend_feature_flag(name, *args, **kwargs)
      enabled = Feature.enabled?(name, *args, **kwargs)

      push_to_gon_attributes(:features, name, enabled)
    end

    def push_to_gon_attributes(key, name, enabled)
      var_name = name.to_s.camelize(:lower)
      # Here the `true` argument signals gon that the value should be merged
      # into any existing ones, instead of overwriting them. This allows you to
      # use this method to push multiple feature flags.
      gon.push({ key => { var_name => enabled } }, true)
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

Gitlab::GonHelper.prepend_mod_with('Gitlab::GonHelper')
