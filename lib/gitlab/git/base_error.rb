# frozen_string_literal: true
require 'grpc'

module Gitlab
  module Git
    class BaseError < StandardError
      METADATA_KEY = :gitaly_error_metadata
      DEBUG_ERROR_STRING_REGEX = /(.*?) debug_error_string:.*$/m
      GRPC_CODES = {
        '0' => 'ok',
        '1' => 'cancelled',
        '2' => 'unknown',
        '3' => 'invalid_argument',
        '4' => 'deadline_exceeded',
        '5' => 'not_found',
        '6' => 'already_exists',
        '7' => 'permission_denied',
        '8' => 'resource_exhausted',
        '9' => 'failed_precondition',
        '10' => 'aborted',
        '11' => 'out_of_range',
        '12' => 'unimplemented',
        '13' => 'internal',
        '14' => 'unavailable',
        '15' => 'data_loss',
        '16' => 'unauthenticated'
      }.freeze

      attr_reader :status, :code, :service, :metadata

      def initialize(msg = nil)
        super && return if msg.nil?

        if msg.is_a?(::GRPC::BadStatus)
          set_grpc_error_code(msg)
          set_grpc_error_metadata(msg)
        end

        super(build_raw_message(msg))
      end

      def build_raw_message(message)
        raw_message = message.to_s
        match = DEBUG_ERROR_STRING_REGEX.match(raw_message)
        match ? match[1] : raw_message
      end

      def set_grpc_error_code(grpc_error)
        @status = grpc_error.code
        @code = GRPC_CODES[@status.to_s]
        @service = 'git'
      end

      def set_grpc_error_metadata(grpc_error)
        @metadata = grpc_error.metadata.fetch(METADATA_KEY, {}).clone
      end
    end
  end
end
