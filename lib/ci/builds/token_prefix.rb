# frozen_string_literal: true

module Ci
  module Builds
    module TokenPrefix
      module_function

      ENCODING_BASE = 16
      SEPARATOR = '_'

      def encode(job)
        gitlab_prefix + encoded_partition_id(job) + SEPARATOR
      end

      def decode_partition(token)
        return unless token.to_s.start_with?(gitlab_prefix)

        encoded_partition_id = token.gsub(gitlab_prefix, '').split(SEPARATOR, 2).first
        return unless encoded_partition_id.present?

        decoded_value = encoded_partition_id.to_i(ENCODING_BASE)
        decoded_value if decoded_value > 0
      end

      def gitlab_prefix
        ::Ci::Build::TOKEN_PREFIX
      end

      def encoded_partition_id(job)
        job.partition_id.to_s(ENCODING_BASE)
      end
    end
  end
end
