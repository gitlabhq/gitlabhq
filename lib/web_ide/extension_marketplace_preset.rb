# frozen_string_literal: true

module WebIde
  class ExtensionMarketplacePreset
    CUSTOM_KEY = "custom"

    def self.all
      [open_vsx]
    end

    def self.open_vsx
      # note: This is effectively a constant so lets memoize
      @open_vsx ||= new(
        "open_vsx",
        "Open VSX",
        # See https://open-vsx.org/swagger-ui/index.html?urls.primaryName=VSCode%20Adapter for OpenVSX Swagger API
        service_url: "https://open-vsx.org/vscode/gallery",
        item_url: "https://open-vsx.org/vscode/item",
        resource_url_template: "https://open-vsx.org/vscode/unpkg/{publisher}/{name}/{versionRaw}/{path}"
      )
    end

    def initialize(key, name, service_url:, item_url:, resource_url_template:)
      @key = key
      @name = name
      @values = {
        service_url: service_url,
        item_url: item_url,
        resource_url_template: resource_url_template
      }.freeze
    end

    attr_reader :key, :name, :values

    def to_h
      {
        key: key,
        name: name,
        values: values
      }
    end
  end
end
