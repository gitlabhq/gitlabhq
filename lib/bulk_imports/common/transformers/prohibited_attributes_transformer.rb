# frozen_string_literal: true

module BulkImports
  module Common
    module Transformers
      class ProhibitedAttributesTransformer
        PROHIBITED_REFERENCES = Regexp.union(
          /\Acached_markdown_version\Z/,
          /\Aid\Z/,
          /_id\Z/,
          /_ids\Z/,
          /_html\Z/,
          /attributes/,
          /\Aremote_\w+_(url|urls|request_header)\Z/ # carrierwave automatically creates these attribute methods for uploads
        ).freeze

        def transform(context, data)
          return unless data

          data.each_with_object({}) do |(key, value), result|
            prohibited = prohibited_key?(key)

            unless prohibited
              result[key] = value.is_a?(Hash) ? transform(context, value) : value
            end
          end
        end

        private

        def prohibited_key?(key)
          key.to_s =~ PROHIBITED_REFERENCES
        end
      end
    end
  end
end
