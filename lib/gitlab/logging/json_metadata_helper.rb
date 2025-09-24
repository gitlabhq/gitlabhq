# frozen_string_literal: true

module Gitlab
  module Logging
    module JsonMetadataHelper
      JSON_METADATA_HEADERS = %i[json_total_elements json_max_array_count json_max_hash_count json_max_depth].freeze

      def store_json_metadata_headers!(payload, request)
        # Add JSON metadata from middleware if available
        json_metadata = request.env[::Gitlab::Middleware::JsonValidation::RACK_ENV_METADATA_KEY]
        return unless json_metadata.present?

        # Add a json_ prefix to distinguish from other metadata
        json_metadata.each do |key, value|
          payload[:"json_#{key}"] = value
        end
      end
    end
  end
end
