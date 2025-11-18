# frozen_string_literal: true

module WebIde
  module ExtensionMarketplace
    DEFAULT_EXTENSION_HOST_DOMAIN = 'cdn.web-ide.gitlab-static.net'

    # Returns true if the ExtensionMarketplace feature is enabled from application settings
    #
    # @return [Boolean]
    def self.feature_enabled_from_application_settings?
      Gitlab::CurrentSettings.vscode_extension_marketplace_enabled?
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
      Settings.get_single_setting(:vscode_extension_marketplace_view_model, user: user)
    end

    def self.reset_extension_host_domain!
      Gitlab::CurrentSettings.update!(
        vscode_extension_marketplace_extension_host_domain: DEFAULT_EXTENSION_HOST_DOMAIN
      )
    end

    def self.extension_host_domain
      Gitlab::CurrentSettings.vscode_extension_marketplace_extension_host_domain
    end

    def self.extension_host_domain_changed?
      extension_host_domain != DEFAULT_EXTENSION_HOST_DOMAIN
    end

    def self.origin_matches_extension_host_regexp
      %r{^https://((?:v--|workbench-)?[a-z0-9]{30,56})\.#{Regexp.escape(extension_host_domain)}$}
    end
  end
end
