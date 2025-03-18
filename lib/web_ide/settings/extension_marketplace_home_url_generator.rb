# frozen_string_literal: true

module WebIde
  module Settings
    class ExtensionMarketplaceHomeUrlGenerator
      # @param [Hash] context
      # @return [Hash]
      def self.generate(context)
        return context unless context.fetch(:requested_setting_names).include?(:vscode_extension_marketplace_home_url)

        context[:settings][:vscode_extension_marketplace_home_url] = home_url(context)
        context
      end

      # @param [Hash] context
      # @return [String] The URL to use for the extension marketplace home
      def self.home_url(context)
        context => {
          settings: {
            vscode_extension_marketplace: Hash => vscode_settings,
          }
        }

        item_url = vscode_settings&.fetch(:item_url, nil)

        return "" unless item_url

        base_url = ::Gitlab::UrlHelpers.normalized_base_url(item_url)

        # NOTE: It's possible for `normalized_base_url` to return something like `://` so let's go ahead and check
        #       that we actually start with `http` or `https`.
        return base_url if /^https?:/.match?(base_url)

        ""
      end

      private_class_method :home_url
    end
  end
end
