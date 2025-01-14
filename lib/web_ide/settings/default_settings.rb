# frozen_string_literal: true

module WebIde
  module Settings
    class DefaultSettings
      SETTINGS_DEPENDENCIES = {
        vscode_extensions_gallery_view_model: [:vscode_extensions_gallery_metadata, :vscode_extensions_gallery]
      }.freeze

      # ALL WEB IDE SETTINGS ARE DECLARED HERE.
      # @return [Hash]
      def self.default_settings
        {
          vscode_extensions_gallery: [
            # See https://sourcegraph.com/github.com/microsoft/vscode@6979fb003bfa575848eda2d3966e872a9615427b/-/blob/src/vs/base/common/product.ts?L96
            #     for the original source of settings entries in the VS Code source code.
            {
              service_url: "https://open-vsx.org/vscode/gallery",
              item_url: "https://open-vsx.org/vscode/item",
              resource_url_template: "https://open-vsx.org/vscode/asset/{publisher}/{name}/{version}/Microsoft.VisualStudio.Code.WebResources/{path}",
              control_url: "",
              nls_base_url: "",
              publisher_url: ""
            },
            Hash
          ],
          vscode_extensions_gallery_metadata: [
            { enabled: false, disabled_reason: :instance_disabled },
            Hash
          ],
          vscode_extensions_gallery_view_model: [
            { enabled: false, reason: :instance_disabled, help_url: '' },
            Hash
          ]
        }
      end
    end
  end
end
