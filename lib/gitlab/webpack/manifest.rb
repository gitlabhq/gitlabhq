require 'webpack/rails/manifest'

module Gitlab
  module Webpack
    class Manifest < ::Webpack::Rails::Manifest
      # Raised if webpack couldn't build one of your assets
      class WebpackError < StandardError
        def initialize(errors)
          super "Error in webpack compile, details follow below:\n#{errors.join("\n\n")}"
        end
      end

      # Raised if a supplied asset does not exist in the webpack manifest
      AssetMissingError = Class.new(StandardError)

      class << self
        def asset_paths(source)
          raise ::Webpack::Rails::Manifest::WebpackError, manifest["errors"] unless manifest_bundled?

          paths = manifest["assetsByChunkName"][source]
          if paths
            # Can be either a string or an array of strings.
            # Do not include source maps as they are not javascript
            [paths].flatten.reject { |p| p =~ /.*\.map$/ }.map do |p|
              "/#{::Rails.configuration.webpack.public_path}/#{p}"
            end
          else
            raise AssetMissingError, "Can't find asset '#{source}' in webpack manifest"
          end
        end

        def entrypoint_paths(source)
          raise ::Webpack::Rails::Manifest::WebpackError, manifest["errors"] unless manifest_bundled?

          entrypoint = manifest["entrypoints"][source]
          if entrypoint && entrypoint["assets"]
            # Can be either a string or an array of strings.
            # Do not include source maps as they are not javascript
            [entrypoint["assets"]].flatten.reject { |p| p =~ /.*\.map$/ }.map do |p|
              "/#{::Rails.configuration.webpack.public_path}/#{p}"
            end
          else
            raise AssetMissingError, "Can't find entry point '#{source}' in webpack manifest"
          end
        end
      end
    end
  end
end
