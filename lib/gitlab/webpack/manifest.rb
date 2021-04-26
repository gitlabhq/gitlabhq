# frozen_string_literal: true

require 'net/http'
require 'uri'

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
          data = if Gitlab.config.webpack.dev_server.enabled
                   load_dev_server_manifest
                 else
                   load_static_manifest
                 end

          Gitlab::Json.parse(data)
        end

        def load_dev_server_manifest
          host = Gitlab.config.webpack.dev_server.host
          port = Gitlab.config.webpack.dev_server.port
          scheme = Gitlab.config.webpack.dev_server.https ? 'https' : 'http'
          uri = Addressable::URI.new(scheme: scheme, host: host, port: port, path: dev_server_path)

          # localhost could be blocked via Gitlab::HTTP
          response = HTTParty.get(uri.to_s, verify: false) # rubocop:disable Gitlab/HTTParty

          return response.body if response.code == 200

          raise "HTTP error #{response.code}"
        rescue OpenSSL::SSL::SSLError, EOFError => e
          ssl_status = Gitlab.config.webpack.dev_server.https ? ' over SSL' : ''
          raise ManifestLoadError.new("Could not connect to webpack-dev-server at #{uri}#{ssl_status}.\n\nIs SSL enabled? Check that settings in `gitlab.yml` and webpack-dev-server match.", e)
        rescue StandardError => e
          raise ManifestLoadError.new("Could not load manifest from webpack-dev-server at #{uri}.\n\nIs webpack-dev-server running? Try running `gdk status webpack` or `gdk tail webpack`.", e)
        end

        def load_static_manifest
          File.read(static_manifest_path)
        rescue StandardError => e
          raise ManifestLoadError.new("Could not load compiled manifest from #{static_manifest_path}.\n\nHave you run `rake gitlab:assets:compile`?", e)
        end

        def static_manifest_path
          ::Rails.root.join(
            Gitlab.config.webpack.output_dir,
            Gitlab.config.webpack.manifest_filename
          )
        end

        def dev_server_path
          "/#{Gitlab.config.webpack.public_path}/#{Gitlab.config.webpack.manifest_filename}"
        end
      end
    end
  end
end
