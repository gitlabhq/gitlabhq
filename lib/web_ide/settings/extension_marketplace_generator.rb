# frozen_string_literal: true

module WebIde
  module Settings
    class ExtensionMarketplaceGenerator
      # @param [Hash] context
      # @return [Hash]
      def self.generate(context)
        return context unless context.fetch(:requested_setting_names).include?(:vscode_extension_marketplace)

        context[:settings][:vscode_extension_marketplace] = extension_marketplace_from_application_settings
        context
      end

      # @param [User, nil] user
      # @return [Hash]
      def self.extension_marketplace_from_application_settings
        settings = Gitlab::CurrentSettings.vscode_extension_marketplace
        preset_key = settings.fetch("preset", ::WebIde::ExtensionMarketplacePreset.open_vsx.key)

        if preset_key == ::WebIde::ExtensionMarketplacePreset::CUSTOM_KEY
          settings.fetch("custom_values").deep_symbolize_keys
        else
          preset = ::WebIde::ExtensionMarketplacePreset.all.find { |x| x.key == preset_key }
          preset&.values
        end
      end

      private_class_method :extension_marketplace_from_application_settings
    end
  end
end
