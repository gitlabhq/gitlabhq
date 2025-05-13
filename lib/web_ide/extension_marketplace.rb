# frozen_string_literal: true

module WebIde
  module ExtensionMarketplace
    # Returns true if the extensions marketplace feature is enabled for any users
    #
    # @return [Boolean]
    def self.feature_enabled_for_any_user?
      # note: Intentionally pass `nil` here since we don't have a user in scope
      feature_enabled_from_application_settings?(user: nil) &&
        feature_flag_enabled_for_any_actor?(:web_ide_extensions_marketplace)
    end

    # Returns true if the extensions marketplace feature is enabled for the given user
    #
    # @param user [User]
    # @return [Boolean]
    def self.feature_enabled?(user:)
      feature_enabled_from_application_settings?(user: user) &&
        feature_enabled_from_flags?(user: user)
    end

    # Returns true if the ExtensionMarketplace feature is enabled from application settings
    #
    # @param user [User, nil] Current user for feature enablement context
    # @return [Boolean]
    def self.feature_enabled_from_application_settings?(user:)
      return true unless should_use_application_settings?(user: user)

      Gitlab::CurrentSettings.vscode_extension_marketplace&.fetch('enabled', false)
    end

    # This value is used when the end-user is accepting the third-party extension marketplace integration.
    #
    # @param user [User] Current user for context
    # @return [String] URL of the VSCode Extension Marketplace home
    def self.marketplace_home_url(user:)
      Gitlab::SafeRequestStore.fetch(:vscode_extension_marketplace_home_url) do
        Settings.get_single_setting(:vscode_extension_marketplace_home_url, user: user)
      end
    end

    # @return [String] URL of the help page for the user preferences for Extensions Marketplace opt-in
    def self.help_preferences_url
      ::Gitlab::Routing.url_helpers.help_page_url('user/profile/preferences.md',
        anchor: 'integrate-with-the-extension-marketplace')
    end

    # This returns a value to be used in the Web IDE config `extensionsGallerySettings`
    # It should match the type expected by the Web IDE:
    #
    # - https://gitlab.com/gitlab-org/gitlab-web-ide/-/blob/51f9e91f890752596e7a3ef51f436fea07885eff/packages/web-ide-types/src/config.ts#L109
    #
    # @param [User] user The current user
    # @return [Hash]
    def self.webide_extension_marketplace_settings(user:)
      Settings.get_single_setting(
        :vscode_extension_marketplace_view_model,
        user: user,
        vscode_extension_marketplace_feature_flag_enabled: feature_enabled_from_flags?(user: user)
      )
    end

    # Returns true if the given flag is enabled for any actor
    #
    # @param [Symbol] flag
    # @return [Boolean]
    def self.feature_flag_enabled_for_any_actor?(flag)
      # Short circuit if we're globally enabled
      return true if Feature.enabled?(flag, nil)

      # The feature could be conditionally applied, so check if `!off?`
      # We also can't *just* check `!off?` because the ActiveRecord might not exist and be default enabled
      feature = Feature.get(flag) # rubocop:disable Gitlab/AvoidFeatureGet -- See above
      feature && !feature.off?
    end

    # Returns true if we should use `feature_enabled_from_application_settings?` to determine feature availability
    #
    # @param user [User, nil] Current user for feature enablement context
    # @return [Boolean]
    def self.should_use_application_settings?(user:)
      if user
        Feature.enabled?(:vscode_extension_marketplace_settings, user)
      else
        feature_flag_enabled_for_any_actor?(:vscode_extension_marketplace_settings)
      end
    end

    # This returns true if the extensions marketplace flags are enabled
    #
    # @param user [User]
    # @return [Boolean]
    def self.feature_enabled_from_flags?(user:)
      Feature.enabled?(:web_ide_extensions_marketplace, user)
    end

    private_class_method :feature_flag_enabled_for_any_actor?, :should_use_application_settings?,
      :feature_enabled_from_flags?
  end
end
