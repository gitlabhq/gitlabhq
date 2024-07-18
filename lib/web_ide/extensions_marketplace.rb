# frozen_string_literal: true

module WebIde
  module ExtensionsMarketplace
    def self.feature_enabled?(user:)
      return false unless Feature.enabled?(:web_ide_extensions_marketplace, user)

      # TODO: Add instance-level setting for this https://gitlab.com/gitlab-org/gitlab/-/issues/451871

      # note: OAuth **must** be enabled for us to use the extension marketplace
      ::WebIde::DefaultOauthApplication.feature_enabled?(user)
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

      if disabled_reason == :opt_in_unset || disabled_reason == :opt_in_disabled
        result[:user_preferences_url] = user_preferences_url
      end

      result
    end

    def self.help_url
      ::Gitlab::Routing.url_helpers.help_page_url('user/project/web_ide/index', anchor: 'extension-marketplace')
    end

    def self.user_preferences_url
      # noinspection RubyResolve -- Rubymine is not correctly recognizing indirectly referenced route helper
      ::Gitlab::Routing.url_helpers.profile_preferences_url(anchor: 'integrations')
    end

    private_class_method :help_url, :user_preferences_url
  end
end
