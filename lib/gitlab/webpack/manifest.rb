# frozen_string_literal: true

require 'webpack/rails/manifest'

module Gitlab
  module Webpack
    class Manifest < ::Webpack::Rails::Manifest
      # Raised if a supplied asset does not exist in the webpack manifest
      AssetMissingError = Class.new(StandardError)

      class << self
        def entrypoint_paths(source)
          raise ::Webpack::Rails::Manifest::WebpackError, manifest["errors"] unless manifest_bundled?

          dll_assets = manifest.fetch("dllAssets", [])
          entrypoint = manifest["entrypoints"][source]
          if entrypoint && entrypoint["assets"]
            # Can be either a string or an array of strings.
            # Do not include source maps as they are not javascript
            [dll_assets, entrypoint["assets"]].flatten.reject { |p| p =~ /.*\.map$/ }.map do |p|
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
