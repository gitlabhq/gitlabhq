# frozen_string_literal: true

module WebIde
  module Settings
    class ExtensionMarketplaceMetadataGenerator
      include Messages

      # NOTE: These `disabled_reason` enumeration values are also referenced/consumed in
      #       the "gitlab-web-ide" and "gitlab-web-ide-vscode-fork" projects
      #       (https://gitlab.com/gitlab-org/gitlab-web-ide & https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork),
      #       so we must ensure that any changes made here are also reflected in those projects.
      #       Please also see EE_DISABLED_REASONS in the relevant EE module.
      DISABLED_REASONS = %i[
        no_user
        no_flag
        instance_disabled
        opt_in_unset
        opt_in_disabled
      ].to_h { |reason| [reason, reason] }.freeze

      # @param [Hash] context
      # @return [Hash]
      def self.generate(context)
        return context unless context.fetch(:requested_setting_names).include?(:vscode_extension_marketplace_metadata)

        context => {
          options: Hash => options,
          settings: {
            vscode_extension_marketplace_home_url: String => marketplace_home_url,
          }
        }
        options_with_defaults = { user: nil, vscode_extension_marketplace_feature_flag_enabled: nil }.merge(options)
        options_with_defaults => {
          user: ::User | NilClass => user,
          vscode_extension_marketplace_feature_flag_enabled: TrueClass | FalseClass | NilClass =>
            extension_marketplace_feature_flag_enabled
        }

        extension_marketplace_metadata = build_metadata(
          user: user,
          flag_enabled: extension_marketplace_feature_flag_enabled,
          marketplace_home_url: marketplace_home_url
        )

        context[:settings][:vscode_extension_marketplace_metadata] = extension_marketplace_metadata
        context
      end

      # @param [User, nil] user
      # @param [Boolean, nil] flag_enabled
      # @return [Hash]
      def self.build_metadata(user:, flag_enabled:, marketplace_home_url:)
        return metadata_disabled(:no_user) unless user
        return metadata_disabled(:no_flag) if flag_enabled.nil?
        return metadata_disabled(:instance_disabled) unless flag_enabled

        unless ::WebIde::ExtensionMarketplace.feature_enabled_from_application_settings?(user: user)
          return metadata_disabled(:instance_disabled)
        end

        build_metadata_for_user(user: user, marketplace_home_url: marketplace_home_url)
      end

      def self.disabled_reasons
        DISABLED_REASONS
      end

      # note: This is overridden in EE
      #
      # @param [User] user
      # @return [Hash]
      def self.build_metadata_for_user(user:, marketplace_home_url:)
        # noinspection RubyNilAnalysis -- RubyMine doesn't realize user can't be nil because of guard clause above
        opt_in_status = ::WebIde::ExtensionMarketplaceOptIn.opt_in_status(
          user: user,
          marketplace_home_url: marketplace_home_url
        ).to_sym

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
            "Supported statuses are: #{Enums::WebIde::ExtensionsMarketplaceOptInStatus.statuses.keys}."
        end
      end

      # @return [Hash]
      def self.metadata_enabled
        { enabled: true }
      end

      # @param [symbol] reason
      # @return [Hash]
      def self.metadata_disabled(reason)
        { enabled: false, disabled_reason: disabled_reasons.fetch(reason) }
      end

      private_class_method :build_metadata, :build_metadata_for_user, :disabled_reasons, :metadata_enabled,
        :metadata_disabled
    end
  end
end

WebIde::Settings::ExtensionMarketplaceMetadataGenerator.prepend_mod
