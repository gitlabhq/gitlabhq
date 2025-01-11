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
    #
    # @return [String] URL of the VSCode Extension Marketplace home
    def self.marketplace_home_url
      "https://open-vsx.org"
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
    def self.webide_extensions_gallery_settings(user:)
      Settings.get(
        [:vscode_extensions_gallery_view_model],
        user: user,
        vscode_extensions_marketplace_feature_flag_enabled: feature_enabled?(user: user)
      ).fetch(:vscode_extensions_gallery_view_model)
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

    private_class_method :feature_flag_enabled_for_any_actor?
  end
end

WebIde::ExtensionsMarketplace.prepend_mod
