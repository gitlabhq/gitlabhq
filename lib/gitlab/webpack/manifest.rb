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

      class << self
        include Gitlab::Utils::StrongMemoize

        def entrypoint_paths(source)
          raise WebpackError, manifest["errors"] unless manifest_bundled?

          dll_assets = manifest.fetch("dllAssets", [])
          entrypoint = manifest["entrypoints"][source]
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

        def asset_paths(source)
          raise WebpackError, manifest["errors"] unless manifest_bundled?

          paths = manifest["assetsByChunkName"][source]
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

        def manifest_bundled?
          !manifest["errors"].any? { |error| error.include? "Module build failed" }
        end

        def manifest
          if Gitlab.config.webpack.dev_server.enabled
            # Only cache at request level if we're in dev server mode, manifest may change ...
            Gitlab::SafeRequestStore.fetch('manifest.json') { load_manifest }
          else
            # ... otherwise cache at class level, as JSON loading/parsing can be expensive
            strong_memoize(:manifest) { load_manifest }
          end
        end

        def load_manifest
          data = Gitlab::Webpack::FileLoader.load(Gitlab.config.webpack.manifest_filename)

          Gitlab::Json.parse(data)
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
