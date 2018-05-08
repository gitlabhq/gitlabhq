require 'webpack/rails/manifest'

module Gitlab
  module Webpack
    class Manifest < ::Webpack::Rails::Manifest
      # Raised if a supplied asset does not exist in the webpack manifest
      AssetMissingError = Class.new(StandardError)

      class << self
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

        def entrypoint_child_paths(source, type: 'preload')
          raise ::Webpack::Rails::Manifest::WebpackError, manifest["errors"] unless manifest_bundled?

          entrypoint = manifest["entrypoints"][source]
          unless entrypoint && entrypoint["childAssets"]
            raise AssetMissingError, "Can't find child assets for entry point '#{source}' in webpack manifest"
          end

          if entrypoint["childAssets"][type].present?
            # Can be either a string or an array of strings.
            # Do not include source maps as they are not javascript
            [entrypoint["childAssets"][type]].flatten.reject { |p| p =~ /.*\.map$/ }.map do |p|
              "/#{::Rails.configuration.webpack.public_path}/#{p}"
            end
          else
            []
          end
        end
      end
    end
  end
end
