# frozen_string_literal: true

module WebIde
  module SettingsSync
    class << self
      # Due to a bug where resource url template was not included
      # "web_ide_https://open-vsx.org/vscode/gallery_https://open-vsx.org/vscode/item_"
      # This hash is used out in the wild, so we don't want to change it...
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178491
      HASH_CONVERSION = {
        # 2e0d3e8c1107f9ccc5ea is the hash of "web_ide_https://open-vsx.org/vscode/gallery_https://open-vsx.org/vscode/item_"
        # e36c431c0e2e1ee82c86 is the hash of "web_ide_https://open-vsx.org/vscode/gallery_https://open-vsx.org/vscode/item_https://open-vsx.org/vscode/asset/{publisher}/{name}/{version}/Microsoft.VisualStudio.Code.WebResources/{path}"
        # 55b10685e181429abe78 is the hash of "web_ide_https://open-vsx.org/vscode/gallery_https://open-vsx.org/vscode/item_https://open-vsx.org/vscode/unpkg/{publisher}/{name}/{version}/{path}"
        "e36c431c0e2e1ee82c86" => "2e0d3e8c1107f9ccc5ea",
        "55b10685e181429abe78" => "2e0d3e8c1107f9ccc5ea"
      }.freeze

      def settings_context_hash(extension_marketplace_settings:)
        return unless extension_marketplace_settings[:enabled]

        settings = extension_marketplace_settings[:vscode_settings]

        # This value determines the extensions settings context.
        # Modifying this value could clear the set of installed extensions for users.
        key = "web_ide_#{settings[:service_url]}_#{settings[:item_url]}_#{settings[:resource_url_template]}"

        hash_value = Digest::SHA256.hexdigest(key).first(20)

        optionally_transform_hash(hash_value)
      end

      private

      def optionally_transform_hash(hash)
        HASH_CONVERSION.fetch(hash, hash)
      end
    end
  end
end
