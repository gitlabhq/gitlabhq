# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize

module Gitlab
  module GonHelper
    include WebpackHelper

    def add_gon_variables
      gon.api_version                   = 'v4'
      gon.default_avatar_url            = default_avatar_url
      gon.max_file_size                 = Gitlab::CurrentSettings.max_attachment_size
      gon.asset_host                    = ActionController::Base.asset_host
      gon.webpack_public_path           = webpack_public_path
      gon.relative_url_root             = Gitlab.config.gitlab.relative_url_root
      gon.user_color_mode               = Gitlab::ColorModes.for_user(current_user).css_class
      gon.user_color_scheme             = Gitlab::ColorSchemes.for_user(current_user).css_class
      gon.markdown_surround_selection   = current_user&.markdown_surround_selection
      gon.markdown_automatic_lists      = current_user&.markdown_automatic_lists
      gon.math_rendering_limits_enabled = Gitlab::CurrentSettings.math_rendering_limits_enabled

      add_browsersdk_tracking

      # Sentry configurations for the browser client are done
      # via `Gitlab::CurrentSettings` from the Admin panel:
      # `/admin/application_settings/metrics_and_profiling`
      if Gitlab::CurrentSettings.sentry_enabled
        gon.sentry_dsn           = Gitlab::CurrentSettings.sentry_clientside_dsn
        gon.sentry_environment   = Gitlab::CurrentSettings.sentry_environment
        gon.sentry_clientside_traces_sample_rate = Gitlab::CurrentSettings.sentry_clientside_traces_sample_rate
      end

      gon.recaptcha_api_server_url = ::Recaptcha.configuration.api_server_url
      gon.recaptcha_sitekey      = Gitlab::CurrentSettings.recaptcha_site_key
      gon.gitlab_url             = Gitlab.config.gitlab.url
      gon.promo_url              = ApplicationHelper.promo_url
      gon.forum_url              = Gitlab::Saas.community_forum_url
      gon.docs_url               = Gitlab::Saas.doc_url
      gon.revision               = Gitlab.revision
      gon.feature_category       = Gitlab::ApplicationContext.current_context_attribute(:feature_category).presence
      gon.gitlab_logo            = ActionController::Base.helpers.asset_path('gitlab_logo.png')
      gon.secure                 = Gitlab.config.gitlab.https
      gon.sprite_icons           = IconsHelper.sprite_icon_path
      gon.sprite_file_icons      = IconsHelper.sprite_file_icons_path
      gon.emoji_sprites_css_path = universal_path_to_stylesheet('emoji_sprites')
      gon.emoji_backend_version  = Gitlab::Emoji::EMOJI_VERSION
      gon.gridstack_css_path     = universal_path_to_stylesheet('lazy_bundles/gridstack')
      gon.test_env               = Rails.env.test?
      gon.disable_animations     = Gitlab.config.gitlab['disable_animations']
      gon.suggested_label_colors = LabelsHelper.suggested_colors
      gon.first_day_of_week      = current_user&.first_day_of_week || Gitlab::CurrentSettings.first_day_of_week
      gon.time_display_relative  = true
      gon.time_display_format    = 0
      gon.ee                     = Gitlab.ee?
      gon.jh                     = Gitlab.jh?
      gon.dot_com                = Gitlab.com?
      gon.uf_error_prefix        = ::Gitlab::Utils::ErrorMessage::UF_ERROR_PREFIX
      gon.pat_prefix             = Gitlab::CurrentSettings.current_application_settings.personal_access_token_prefix
      gon.keyboard_shortcuts_enabled = current_user ? current_user.keyboard_shortcuts_enabled : true

      gon.diagramsnet_url = Gitlab::CurrentSettings.diagramsnet_url if Gitlab::CurrentSettings.diagramsnet_enabled

      if current_user
        gon.version = Gitlab::VERSION # publish version only for logged in users
        gon.current_user_id = current_user.id
        gon.current_username = current_user.username
        gon.current_user_fullname = current_user.name
        gon.current_user_avatar_url = current_user.avatar_url
        gon.time_display_relative = current_user.time_display_relative
        gon.time_display_format = current_user.time_display_format

        if current_user.user_preference
          gon.current_user_use_work_items_view = current_user.user_preference.use_work_items_view || false
          gon.text_editor = current_user.user_preference.text_editor
        end
      end

      if current_organization && Feature.enabled?(:ui_for_organizations, current_user)
        gon.current_organization = current_organization.slice(:id, :name, :web_url, :avatar_url)
      end

      # Initialize gon.features with any flags that should be
      # made globally available to the frontend
      push_frontend_feature_flag(:source_editor_toolbar)
      push_frontend_feature_flag(:vscode_web_ide, current_user)
      push_frontend_feature_flag(:ui_for_organizations, current_user)
      push_frontend_feature_flag(:organization_switching, current_user)
      push_frontend_feature_flag(:find_and_replace, current_user)
      # To be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/399248
      push_frontend_feature_flag(:remove_monitor_metrics)
      push_frontend_feature_flag(:work_items_view_preference, current_user)
      push_frontend_feature_flag(:search_button_top_right, current_user)
      push_frontend_feature_flag(:markdown_paste_url, current_user)
      push_frontend_feature_flag(:merge_request_dashboard, current_user, type: :wip)
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

    def push_frontend_ability(ability:, user:, resource: :global)
      push_to_gon_attributes(
        :abilities,
        ability,
        Ability.allowed?(user, ability, resource)
      )
    end

    # Exposes the state of a feature flag to the frontend code.
    # Can be used for more complex feature flag checks.
    #
    # name - The name of the feature flag, e.g. `my_feature`.
    # enabled - Boolean to be pushed directly to the frontend. Should be fetched by checking a feature flag.
    def push_force_frontend_feature_flag(name, enabled)
      push_to_gon_attributes(:features, name, !!enabled)
    end

    def push_namespace_setting(key, object)
      return unless object&.namespace_settings.respond_to?(key)

      gon.push({ key => object.namespace_settings.public_send(key) }) # rubocop:disable GitlabSecurity/PublicSend
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

    def add_browsersdk_tracking
      return unless Gitlab.com?

      return if ENV['GITLAB_ANALYTICS_URL'].blank? || ENV['GITLAB_ANALYTICS_ID'].blank?

      gon.analytics_url = ENV['GITLAB_ANALYTICS_URL']
      gon.analytics_id = ENV['GITLAB_ANALYTICS_ID']
    end

    # `::Current.organization` is only valid within the context of a request,
    # but it can be called from everywhere. So how do we avoid accidentally
    # calling it outside of the context of a request? We banned it with
    # Rubocop.
    #
    # This method is acceptable because it is only included by controllers.
    # This method intentionally looks like Devise's `current_user` method,
    # which has similar properties.
    # rubocop:disable Gitlab/AvoidCurrentOrganization -- This method follows the spirit of the rule
    def current_organization
      return unless ::Current.organization_assigned

      Organizations::FallbackOrganizationTracker.without_tracking { ::Current.organization }
    end
    # rubocop:enable Gitlab/AvoidCurrentOrganization
  end
end

Gitlab::GonHelper.prepend_mod_with('Gitlab::GonHelper')
