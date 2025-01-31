# frozen_string_literal: true

module WebIde
  module SettingsSync
    class << self
      # Due to a bug where resource url template was not included
      # "web_ide_https://open-vsx.org/vscode/gallery_https://open-vsx.org/vscode/item_"
      # This hash is used out in the wild, so we don't want to change it...
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178491
      CURRENT_DEFAULT_SETTINGS_HASH = "2e0d3e8c1107f9ccc5ea"

      # The actual hash we calculate for default settings, but needs to be mapped to the CURRENT one for compatability
      DEFAULT_SETTINGS_HASH = "e36c431c0e2e1ee82c86"

      def settings_context_hash(extensions_gallery_settings:)
        return unless extensions_gallery_settings[:enabled]

        settings = extensions_gallery_settings[:vscode_settings]

        # This value determines the extensions settings context.
        # Modifying this value could clear the set of installed extensions for users.
        key = "web_ide_#{settings[:service_url]}_#{settings[:item_url]}_#{settings[:resource_url_template]}"

        hash_value = Digest::SHA256.hexdigest(key).first(20)

        optionally_transform_hash(hash_value)
      end

      private

      def optionally_transform_hash(hash)
        return CURRENT_DEFAULT_SETTINGS_HASH if hash == DEFAULT_SETTINGS_HASH

        hash
      end
    end
  end
end
