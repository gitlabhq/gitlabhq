# frozen_string_literal: true

module Gitlab
  module Markdown
    module IframeProviders
      class Provider
        ID_FORMAT = /\A[a-z][a-z0-9_]*\z/
        KEYS = %w[name matches requires src sandbox require_activation].freeze

        attr_reader :id, :name, :matches, :requires, :src, :src_origin, :sandbox, :require_activation

        class << self
          def from_config(id, entry)
            fail!(id, 'ID must match /[a-z][a-z0-9_]*/') unless id.is_a?(String) && id.match?(ID_FORMAT)
            fail!(id, 'must be a mapping') unless entry.is_a?(Hash)

            unknown_keys = entry.keys - KEYS
            fail!(id, "unknown keys: #{unknown_keys.join(', ')}") if unknown_keys.any?

            matches = parse_matches(id, entry['matches'])
            requires = parse_requires(id, entry.fetch('requires', {}))
            src = parse_src(id, entry['src'], matches, requires)
            sandbox = parse_sandbox(id, entry['sandbox'], src)

            new(
              id: id,
              name: parse_name(id, entry['name']),
              matches: matches,
              requires: requires,
              src: src,
              src_origin: Addressable::URI.parse(src).origin,
              sandbox: sandbox,
              require_activation: parse_require_activation(id, entry.fetch('require_activation', true))
            )
          end

          private

          def fail!(id, message)
            raise ConfigError, "provider '#{id}': #{message}"
          end

          def parse_name(id, name)
            fail!(id, "missing 'name'") unless name.is_a?(String) && name.present?

            name
          end

          def parse_matches(id, matches)
            fail!(id, "'matches' must be a non-empty list") unless matches.is_a?(Array) && matches.any?

            matches.map { |config| MatchRule.from_config(id, config) }
          end

          def parse_requires(id, requires)
            valid = requires.is_a?(Hash) &&
              requires.keys.all?(String) &&
              requires.values.all? { |values| values.is_a?(Array) && values.all?(String) }

            fail!(id, "'requires' must be a mapping of capture names to lists of strings") unless valid

            requires
          end

          def parse_src(id, src, matches, requires)
            fail!(id, "missing 'src'") unless src.is_a?(String) && src.present?

            uri = begin
              Addressable::URI.parse(src)
            rescue Addressable::URI::InvalidURIError
              fail!(id, "'src' is not a valid URL")
            end

            fail!(id, "'src' must be an https URL with a host") unless uri.scheme == 'https' && uri.host.present?

            needed = src.scan(PLACEHOLDER).flatten | requires.keys

            matches.each do |rule|
              missing = needed - rule.capture_names
              next if missing.none?

              fail!(id, "captures #{missing.join(', ')} are not provided by the match rule for #{rule.host}")
            end

            src
          end

          def parse_sandbox(id, sandbox, src)
            fail!(id, "'sandbox' must be a list of flags") unless sandbox.is_a?(Array) && sandbox.all?(String)

            unpermitted = sandbox - PERMITTED_SANDBOX_FLAGS
            fail!(id, "unpermitted sandbox flags: #{unpermitted.join(' ')}") if unpermitted.any?

            if sandbox.include?('allow-same-origin') && hosted_by_instance?(Addressable::URI.parse(src).normalized_host)
              fail!(id, "'src' must not be hosted by this GitLab instance when 'allow-same-origin' is set")
            end

            sandbox
          end

          def parse_require_activation(id, require_activation)
            fail!(id, "'require_activation' must be a boolean") unless [true, false].include?(require_activation)

            require_activation
          end

          def hosted_by_instance?(host)
            pages_host = Gitlab.config.pages.host.downcase

            host == Gitlab.config.gitlab.host.downcase || host == pages_host || host.end_with?(".#{pages_host}")
          end
        end

        def initialize(id:, name:, matches:, requires:, src:, src_origin:, sandbox:, require_activation:)
          @id = id
          @name = name
          @matches = matches
          @requires = requires
          @src = src
          @src_origin = src_origin
          @sandbox = sandbox
          @require_activation = require_activation
        end

        def match(uri)
          matches.each do |rule|
            captures = rule.match(uri)
            next unless captures && satisfies_requires?(captures)

            return expand_src(captures)
          end

          nil
        end

        private

        def satisfies_requires?(captures)
          requires.all? { |name, permitted| permitted.include?(captures[name]) }
        end

        def expand_src(captures)
          src.gsub(PLACEHOLDER) do
            Addressable::URI.encode_component(
              captures.fetch(::Regexp.last_match(1)),
              Addressable::URI::CharacterClasses::UNRESERVED)
          end
        end
      end
    end
  end
end
