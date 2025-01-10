# frozen_string_literal: true

module WebIde
  module SettingsSync
    class << self
      def settings_context_hash(extensions_gallery_settings:)
        return unless extensions_gallery_settings[:enabled]

        settings = extensions_gallery_settings[:vscode_settings]

        # This value determines the extensions settings context.
        # Modifying this value could clear the set of installed extensions for users.
        key = "web_ide_#{settings[:service_url]}_#{settings[:item_url]}_#{settings[:resource_template_url]}"
        Digest::SHA256.hexdigest(key).first(20)
      end
    end
  end
end
