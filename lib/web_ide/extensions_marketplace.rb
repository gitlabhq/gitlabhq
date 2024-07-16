# frozen_string_literal: true

module WebIde
  module ExtensionsMarketplace
    # NOTE: These `disabled_reason` enumeration values are also referenced/consumed in
    #       the "gitlab-web-ide" and "gitlab-web-ide-vscode-fork" projects
    #       (https://gitlab.com/gitlab-org/gitlab-web-ide & https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork),
    #       so we must ensure that any changes made here are also reflected in those projects.
    DISABLED_REASONS =
      %i[
        no_user
        no_flag
        instance_disabled
        opt_in_unset
        opt_in_disabled
      ].to_h { |reason| [reason, reason] }.freeze

    class << self
      def feature_enabled?(user:)
        # TODO: Add instance-level setting for this https://gitlab.com/gitlab-org/gitlab/-/issues/451871

        # note: OAuth **must** be enabled for us to use the extension marketplace
        ::WebIde::DefaultOauthApplication.feature_enabled?(user) &&
          Feature.enabled?(:web_ide_extensions_marketplace, user)
      end

      def vscode_settings
        # TODO: Add instance-level setting for this https://gitlab.com/gitlab-org/gitlab/-/issues/451871
        # TODO: We need to harmonize this with `lib/remote_development/settings/defaults_initializer.rb`
        #       https://gitlab.com/gitlab-org/gitlab/-/issues/460515
        {
          item_url: 'https://open-vsx.org/vscode/item',
          service_url: 'https://open-vsx.org/vscode/gallery',
          resource_url_template:
            'https://open-vsx.org/vscode/unpkg/{publisher}/{name}/{version}/{path}',
          control_url: '',
          nls_base_url: '',
          publisher_url: ''
        }
      end

      # This value is used when the end-user is accepting the third-party extension marketplace integration.
      def marketplace_home_url
        "https://open-vsx.org"
      end

      def help_url
        ::Gitlab::Routing.url_helpers.help_page_url('user/project/web_ide/index', anchor: 'extension-marketplace')
      end

      def help_preferences_url
        ::Gitlab::Routing.url_helpers.help_page_url('user/profile/preferences',
          anchor: 'integrate-with-the-extension-marketplace')
      end

      def user_preferences_url
        ::Gitlab::Routing.url_helpers.profile_preferences_url(anchor: 'integrations')
      end

      # This returns a value to be used in the Web IDE config `extensionsGallerySettings`
      # It should match the type expected by the Web IDE:
      #
      # - https://gitlab.com/gitlab-org/gitlab-web-ide/-/blob/51f9e91f890752596e7a3ef51f436fea07885eff/packages/web-ide-types/src/config.ts#L109
      #
      # @return [Hash]
      def webide_extensions_gallery_settings(user:)
        flag_enabled = feature_enabled?(user: user)
        metadata = metadata_for_user(user: user, flag_enabled: flag_enabled)

        return { enabled: true, vscode_settings: vscode_settings } if metadata.fetch(:enabled)

        disabled_reason = metadata.fetch(:disabled_reason, nil)
        result = { enabled: false, reason: disabled_reason, help_url: help_url }

        if disabled_reason == :opt_in_unset || disabled_reason == :opt_in_disabled
          result[:user_preferences_url] = user_preferences_url
        end

        result
      end

      # @param [User, nil] user
      # @param [Boolean, nil] flag_enabled
      # @return [Hash]
      def metadata_for_user(user:, flag_enabled:)
        return metadata_disabled(:no_user) unless user
        return metadata_disabled(:no_flag) if flag_enabled.nil?
        return metadata_disabled(:instance_disabled) unless flag_enabled

        # noinspection RubyNilAnalysis -- RubyMine doesn't realize user can't be nil because of guard clause above
        opt_in_status = user.extensions_marketplace_opt_in_status.to_sym

        case opt_in_status
        when :enabled
          metadata_enabled
        when :unset
          metadata_disabled(:opt_in_unset)
        when :disabled
          metadata_disabled(:opt_in_disabled)
        else
          # This is an internal bug due to an enumeration mismatch/inconsistency with the model
          raise "Invalid user.extensions_marketplace_opt_in_status: '#{opt_in_status}'. " \
            "Supported statuses are: #{Enums::WebIde::ExtensionsMarketplaceOptInStatus.statuses.keys}." # rubocop:disable Layout/LineEndStringConcatenationIndentation -- This is already changed in the next version of gitlab-styles
        end
      end

      private

      def metadata_enabled
        { enabled: true }
      end

      def metadata_disabled(reason)
        { enabled: false, disabled_reason: DISABLED_REASONS.fetch(reason) }
      end
    end
  end
end
