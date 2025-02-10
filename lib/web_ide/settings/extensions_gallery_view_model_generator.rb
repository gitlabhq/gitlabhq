# frozen_string_literal: true

module WebIde
  module Settings
    class ExtensionsGalleryViewModelGenerator
      # @param [Hash] context
      # @return [Hash]
      def self.generate(context)
        return context unless context.fetch(:requested_setting_names).include?(:vscode_extensions_gallery_view_model)

        context[:settings][:vscode_extensions_gallery_view_model] = build_view_model(context)

        context
      end

      # Builds the value for :vscode_extensions_gallery_view_model
      #
      # @param [Hash] context The settings railway context
      # @return [Hash] value for :vscode_extensions_gallery_view_model
      def self.build_view_model(context)
        context => {
          options: {
            user: ::User => user
          },
          settings: {
            vscode_extensions_gallery: Hash => vscode_settings,
            vscode_extensions_gallery_metadata: Hash => metadata
          }
        }

        return { enabled: true, vscode_settings: vscode_settings } if metadata.fetch(:enabled)

        disabled_reason = metadata.fetch(:disabled_reason)

        result = { enabled: false, reason: disabled_reason, help_url: help_url }

        result.merge(gallery_disabled_extra_attributes(disabled_reason: disabled_reason, user: user))
      end

      # Returns extra attributes for the view model when the extensions marketplace is disabled
      #
      # Overridden in EE
      #
      # @param [Symbol] disabled_reason The reason why the gallery is disabled
      # @param [User] user The current user (only used in EE override)
      # @return [Hash] Extra attributes for the view model
      #
      # rubocop:disable Lint/UnusedMethodArgument -- `user:` param is used in EE
      def self.gallery_disabled_extra_attributes(disabled_reason:, user:)
        return { user_preferences_url: user_preferences_url } if disabled_reason == :opt_in_unset
        return { user_preferences_url: user_preferences_url } if disabled_reason == :opt_in_disabled

        {}
      end
      # rubocop:enable Lint/UnusedMethodArgument

      # Returns help url for Web IDE extensions marketplace
      #
      # @return [String]
      def self.help_url
        ::Gitlab::Routing.url_helpers.help_page_url('user/project/web_ide/_index.md', anchor: 'extension-marketplace')
      end

      # Returns user preferences url for changing the user's opt-in status for VSCode extensions marketplace
      #
      # @return [String]
      def self.user_preferences_url
        # noinspection RubyResolve -- Rubymine is not correctly recognizing indirectly referenced route helper
        ::Gitlab::Routing.url_helpers.profile_preferences_url(anchor: 'integrations')
      end

      private_class_method :build_view_model, :gallery_disabled_extra_attributes, :help_url, :user_preferences_url
    end
  end
end

WebIde::Settings::ExtensionsGalleryViewModelGenerator.prepend_mod
