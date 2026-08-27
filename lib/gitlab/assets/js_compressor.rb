# frozen_string_literal: true

module Gitlab
  module Assets
    class JsCompressor
      # scripts/frontend/po_to_json.js already emits locale bundles as a single line of
      # JSON, so Terser reclaims ~0.07% of a 3.2 MB file for ~2s of work. Sprockets
      # compresses serially and there are ~80 of these bundles.
      PREMINIFIED = %r{/app/assets/javascripts/locale/[^/]+/app\.js\z}

      # Bump whenever PREMINIFIED or the skip/delegate logic changes, so Sprockets does
      # not serve output cached under the old behaviour.
      VERSION = '1'

      class << self
        def call(input)
          return input[:data] if PREMINIFIED.match?(input[:filename].to_s)

          Terser::Compressor.call(input)
        end

        def cache_key
          @cache_key ||= "#{Terser::Compressor.cache_key}:#{name}:#{VERSION}"
        end
      end
    end
  end
end
