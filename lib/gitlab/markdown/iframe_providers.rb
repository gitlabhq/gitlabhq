# frozen_string_literal: true

module Gitlab
  module Markdown
    module IframeProviders
      PROVIDERS_PATH = Rails.root.join('config/iframe_providers.yml').freeze

      PERMITTED_SANDBOX_FLAGS = %w[
        allow-scripts
        allow-same-origin
        allow-popups
        allow-popups-to-escape-sandbox
        allow-presentation
      ].freeze

      PLACEHOLDER = /\{(\w+)\}/

      ConfigError = Class.new(StandardError)

      Match = Struct.new(:url, :provider, keyword_init: true)

      class << self
        def match(url)
          return if url.blank?

          uri = begin
            Addressable::URI.parse(url)
          rescue Addressable::URI::InvalidURIError
            nil
          end

          return unless uri&.normalized_scheme == 'https'

          enabled_providers.each do |provider|
            matched = provider.match(uri)
            return Match.new(url: matched, provider: provider) if matched
          end

          nil
        end

        def known_providers
          @known_providers ||= load_providers!
        end

        def enabled_providers
          allowlist = Gitlab::CurrentSettings.iframe_rendering_allowlist
          known_providers.select { |provider| allowlist.include?(provider.id) }
        end

        def reset!
          @known_providers = nil
        end

        private

        def load_config!
          YAML.safe_load_file(PROVIDERS_PATH)
        end

        def load_providers!
          config = load_config!
          raise ConfigError, "#{PROVIDERS_PATH.basename}: expected a mapping of provider IDs" unless config.is_a?(Hash)

          config.map { |id, entry| Provider.from_config(id, entry) }.freeze
        end
      end
    end
  end
end
