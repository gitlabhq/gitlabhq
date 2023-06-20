# frozen_string_literal: true

require "carrierwave/uploader/url"

if Gem::Version.create(CarrierWave::VERSION) >= Gem::Version.create('2.0')
  raise ScriptError,
    "CarrierWave was upgraded to #{CarrierWave::VERSION} and this patch is not required anymore"
end

# rubocop: disable Style/GuardClause
module CarrierWave
  module Uploader
    module Url
      ##
      # === Parameters
      #
      # [Hash] optional, the query params (only AWS)
      #
      # === Returns
      #
      # [String] the location where this file is accessible via a url
      #
      def url(options = {})
        if file.respond_to?(:url)
          tmp_url = file.method(:url).arity == 0 ? file.url : file.url(options)

          return tmp_url if tmp_url.present?
        end

        if file.respond_to?(:path)
          path = encode_path(file.path.sub(File.expand_path(root), ''))

          if host = asset_host
            if host.respond_to? :call
              "#{host.call(file)}#{path}"
            else
              "#{host}#{path}"
            end
          else
            (base_path || "") + path
          end
        end
      end
    end
  end
end
# rubocop: enable Style/GuardClause
