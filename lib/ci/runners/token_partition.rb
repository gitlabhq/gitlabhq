# frozen_string_literal: true

module Ci
  module Runners
    class TokenPartition
      # @see app/assets/javascripts/lib/utils/secret_detection_patterns.js
      LEGACY_TOKEN_PATTERN = /\A(?<registration_type>glrt-)?(?<runner_type>t\d_)[0-9a-zA-Z_-]{20}/

      def initialize(token)
        @token = token
      end

      def decode
        runner_type_integer =
          partition_from_legacy_token || partition_from_v1_routable_payload_token
        return if runner_type_integer.blank?

        ::Ci::Runner.runner_types.key(runner_type_integer)
      end

      private

      attr_reader :token

      def partition_from_v1_routable_payload_token
        ::Authn::TokenField::Decoders::V1::RoutablePayload
          .new(token)
          .decode
          .try { |payload| payload['t'] }
      end

      def partition_from_legacy_token
        match_data = LEGACY_TOKEN_PATTERN.match(token)
        return if match_data.blank?

        match_data[:runner_type][1].to_i
      end
    end
  end
end
