# frozen_string_literal: true

module Gitlab
  module Webpack
    class Manifest
      # Raised if we can't read our webpack manifest for whatever reason
      class ManifestLoadError < StandardError
        def initialize(message, orig)
          super "#{message}\n\n(original error #{orig.class.name}: #{orig})"
        end
      end

      # Raised if webpack couldn't build one of your entry points
      class WebpackError < StandardError
        def initialize(errors)
          super "Error in webpack compile, details follow below:\n#{errors.join("\n\n")}"
        end
      end

      # Raised if a supplied entry point does not exist in the webpack manifest
      AssetMissingError = Class.new(StandardError)

      RSPACK_MANIFEST_FILENAME = 'manifest.rspack.json'

      class << self
        include Gitlab::Utils::StrongMemoize

        def entrypoint_paths(source, manifest_filename: default_manifest_filename)
          data = manifest(manifest_filename)
          raise WebpackError, data["errors"] unless manifest_bundled?(data)

          dll_assets = data.fetch("dllAssets", [])
          entrypoint = data["entrypoints"][source]
          if entrypoint && entrypoint["assets"]
            # Can be either a string or an array of strings.
            # Do not include source maps as they are not javascript
            [dll_assets, entrypoint["assets"]].flatten.reject { |p| p =~ /.*\.map$/ }.map do |p|
              "/#{Gitlab.config.webpack.public_path}/#{p}"
            end
          else
            raise AssetMissingError, "Can't find asset '#{source}' in webpack manifest"
          end
        end

        def asset_paths(source, manifest_filename: default_manifest_filename)
          data = manifest(manifest_filename)
          raise WebpackError, data["errors"] unless manifest_bundled?(data)

          paths = data["assetsByChunkName"][source]
          if paths
            # Can be either a string or an array of strings.
            # Do not include source maps as they are not javascript
            [paths].flatten.reject { |p| p =~ /.*\.map$/ }.map do |p|
              "/#{Gitlab.config.webpack.public_path}/#{p}"
            end
          else
            raise AssetMissingError, "Can't find entry point '#{source}' in webpack manifest"
          end
        end

        def clear_manifest!
          clear_memoization(:manifest)
        end

        private

        def default_manifest_filename
          Gitlab.config.webpack.manifest_filename
        end

        def manifest_bundled?(data)
          !data["errors"].any? { |error| error.include? "Module build failed" }
        end

        def manifest(manifest_filename)
          if Gitlab.config.webpack.dev_server.enabled
            # Only cache at request level if we're in dev server mode, manifest may change ...
            Gitlab::SafeRequestStore.fetch("webpack_manifest:#{manifest_filename}") { load_manifest(manifest_filename) }
          else
            # ... otherwise cache at class level, as JSON loading/parsing can be expensive
            strong_memoize_with(:manifest, manifest_filename) { load_manifest(manifest_filename) }
          end
        end

        def load_manifest(manifest_filename)
          data = Gitlab::Webpack::FileLoader.load(manifest_filename)

          # We intentionally use Gitlab::Json.parse here (not SafeParser) because
          # the webpack manifest can exceed the memory limits enforced by SafeParser.
          Gitlab::Json.parse(data) # rubocop:disable Gitlab/JsonSafeParse -- Manifest can exceed SafeParser memory limits
        rescue Gitlab::Webpack::FileLoader::StaticLoadError => e
          raise ManifestLoadError.new("Could not load compiled manifest from #{e.uri}.\n\nHave you run `rake gitlab:assets:compile`?", e.original_error)
        rescue Gitlab::Webpack::FileLoader::DevServerSSLError => e
          ssl_status = Gitlab.config.webpack.dev_server.https ? ' over SSL' : ''
          raise ManifestLoadError.new("Could not connect to webpack-dev-server at #{e.uri}#{ssl_status}.\n\nIs SSL enabled? Check that settings in `gitlab.yml` and webpack-dev-server match.", e.original_error)
        rescue Gitlab::Webpack::FileLoader::DevServerLoadError => e
          raise ManifestLoadError.new("Could not load manifest from webpack-dev-server at #{e.uri}.\n\nIs webpack-dev-server running? Try running `gdk status webpack` or `gdk tail webpack`.", e.original_error)
        end
      end
    end
  end
end
