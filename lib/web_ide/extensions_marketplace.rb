# frozen_string_literal: true

module WebIde
  module ExtensionsMarketplace
    # This returns true if the extensions marketplace feature is available to any users
    #
    # @return [Boolean]
    def self.feature_enabled_for_any_user?
      feature_flag_enabled_for_any_actor?(:web_ide_extensions_marketplace) &&
        feature_flag_enabled_for_any_actor?(:vscode_web_ide)
    end

    # This returns true if the extensions marketplace feature is available to the given user
    #
    # @param user [User]
    # @return [Boolean]
    def self.feature_enabled?(user:)
      Feature.enabled?(:web_ide_extensions_marketplace, user) &&
        Feature.enabled?(:vscode_web_ide, user)
    end

    # This value is used when the end-user is accepting the third-party extension marketplace integration.
    def self.marketplace_home_url
      "https://open-vsx.org"
    end

    def self.help_preferences_url
      ::Gitlab::Routing.url_helpers.help_page_url('user/profile/preferences',
        anchor: 'integrate-with-the-extension-marketplace')
    end

    # This returns a value to be used in the Web IDE config `extensionsGallerySettings`
    # It should match the type expected by the Web IDE:
    #
    # - https://gitlab.com/gitlab-org/gitlab-web-ide/-/blob/51f9e91f890752596e7a3ef51f436fea07885eff/packages/web-ide-types/src/config.ts#L109
    #
    # @return [Hash]
    def self.webide_extensions_gallery_settings(user:)
      # TODO: Add instance-level setting for extensions gallery settings.
      #       See https://gitlab.com/gitlab-org/gitlab/-/issues/451871

      settings = Settings.get(
        [:vscode_extensions_gallery, :vscode_extensions_gallery_metadata],
        user: user,
        vscode_extensions_marketplace_feature_flag_enabled: feature_enabled?(user: user)
      )

      settings => {
        vscode_extensions_gallery: Hash => vscode_settings,
        vscode_extensions_gallery_metadata: Hash => metadata
      }

      # TODO: Introduce a Service layer and standard ServiceResponse interface,
      #       and move the following logic either down into the Settings::Main ROP chain
      #       or up into the Service layer.
      #       See https://gitlab.com/gitlab-org/gitlab/-/issues/471300

      return { enabled: true, vscode_settings: vscode_settings } if metadata.fetch(:enabled)

      disabled_reason = metadata.fetch(:disabled_reason)

      result = { enabled: false, reason: disabled_reason, help_url: help_url }

      result.merge(gallery_disabled_extra_attributes(disabled_reason: disabled_reason, user: user))
    end

    # rubocop:disable Lint/UnusedMethodArgument -- `user:` param is used in EE
    def self.gallery_disabled_extra_attributes(disabled_reason:, user:)
      return { user_preferences_url: user_preferences_url } if disabled_reason == :opt_in_unset
      return { user_preferences_url: user_preferences_url } if disabled_reason == :opt_in_disabled

      {}
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def self.help_url
      ::Gitlab::Routing.url_helpers.help_page_url('user/project/web_ide/index', anchor: 'extension-marketplace')
    end

    def self.user_preferences_url
      # noinspection RubyResolve -- Rubymine is not correctly recognizing indirectly referenced route helper
      ::Gitlab::Routing.url_helpers.profile_preferences_url(anchor: 'integrations')
    end

    def self.feature_flag_enabled_for_any_actor?(flag)
      # Short circuit if we're globally enabled
      return true if Feature.enabled?(flag, nil)

      # The feature could be conditionally applied, so check if `!off?`
      # We also can't *just* check `!off?` because the ActiveRecord might not exist and be default enabled
      feature = Feature.get(flag) # rubocop:disable Gitlab/AvoidFeatureGet -- See above
      feature && !feature.off?
    end

    private_class_method :help_url, :user_preferences_url, :feature_flag_enabled_for_any_actor?
  end
end

WebIde::ExtensionsMarketplace.prepend_mod
