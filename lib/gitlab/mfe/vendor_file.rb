# frozen_string_literal: true

module Gitlab
  module Mfe
    # Loader for the committed MFE pin file. Lockfile semantics: a broken or
    # under-specified pin file fails loudly instead of silently disabling
    # delivery; only an empty `apps:` list is a clean no-op.
    class VendorFile
      CONFIG_PATH = 'vendor/mfe.yml'

      NAME_PATTERN = /\A[a-z0-9][a-z0-9_-]*\z/
      VERSION_PATTERN = /\A\d+\.\d+\.\d+\z/
      SHA256_PATTERN = /\A[0-9a-f]{64}\z/

      InvalidEntryError = Class.new(StandardError)

      # `sha` is the SHA256 of the app's `{version}/manifest.json` bytes; the
      # baker refuses to bake unless the fetched manifest hashes to it.
      Entry = Struct.new(
        :name,
        :version,
        :sha,
        keyword_init: true
      )

      class << self
        include ::Gitlab::Utils::StrongMemoize

        def entries
          load_entries.each(&:freeze).freeze
        end
        strong_memoize_attr :entries

        # Test-only.
        def reset!
          clear_memoization(:entries)
          nil
        end

        private

        def load_entries
          raw = load_file
          apps = raw['apps']
          return [] if apps.blank?

          raise InvalidEntryError, "invalid MFE pin file: 'apps' must be a list" unless apps.is_a?(Array)

          entries = apps.map { |attributes| build_entry(attributes) }
          validate_unique_names!(entries)
          entries
        end

        def validate_unique_names!(entries)
          duplicates = entries.map(&:name).tally.select { |_, count| count > 1 }.keys
          return if duplicates.empty?

          raise InvalidEntryError, "duplicate MFE pins: #{duplicates.join(', ')}"
        end

        def load_file
          # This is a file we author and commit ourselves, not user-supplied
          # CI config, so the plain YAML loader is enough here.
          raw = ::YAML.safe_load(read_file, aliases: true)
          return {} if raw.blank?

          raise InvalidEntryError, 'invalid MFE pin file: root must be a map' unless raw.is_a?(Hash)

          raw.deep_stringify_keys
        rescue ::Psych::Exception, ArgumentError => e
          raise InvalidEntryError, "could not parse vendor file: #{e.message}"
        end

        def config_file_path
          Rails.root.join(CONFIG_PATH)
        end

        # A missing pin file is a broken checkout, not a no-op.
        def read_file
          File.read(config_file_path)
        rescue SystemCallError => e
          raise InvalidEntryError, "could not read vendor file: #{e.message}"
        end

        def build_entry(attributes)
          unless attributes.is_a?(Hash)
            raise InvalidEntryError, "invalid MFE pin entry: expected a map, got #{attributes.inspect}"
          end

          name = attributes['name'].to_s
          version = attributes['version'].to_s
          sha = attributes['sha'].to_s

          unless NAME_PATTERN.match?(name)
            raise InvalidEntryError, "invalid MFE name '#{name}': must match #{NAME_PATTERN.source}"
          end

          unless VERSION_PATTERN.match?(version)
            raise InvalidEntryError,
              "invalid version '#{version}' for MFE '#{name}': must be MAJOR.MINOR.PATCH"
          end

          unless SHA256_PATTERN.match?(sha)
            raise InvalidEntryError,
              "invalid sha '#{sha}' for MFE '#{name}': must be 64 lowercase hex characters"
          end

          Entry.new(name: name.freeze, version: version.freeze, sha: sha.freeze)
        end
      end
    end
  end
end
