# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class ExtensionsGalleryMetadataGenerator
      include Messages

      # @param [Hash] context
      # @return [Hash]
      def self.generate(context)
        context => { options: Hash => options }
        options_with_defaults = { user: nil, vscode_extensions_marketplace_feature_flag_enabled: nil }.merge(options)
        options_with_defaults => {
          user: ::User | NilClass => user,
          vscode_extensions_marketplace_feature_flag_enabled: TrueClass | FalseClass | NilClass =>
            extensions_marketplace_feature_flag_enabled
        }

        extensions_gallery_metadata = ::WebIde::ExtensionsMarketplace.metadata_for_user(
          user: user,
          flag_enabled: extensions_marketplace_feature_flag_enabled
        )

        context[:settings][:vscode_extensions_gallery_metadata] = extensions_gallery_metadata
        context
      end
    end
  end
end
