# frozen_string_literal: true

require_relative 'grpc/client/stream_request_enumerator'
require_relative 'grpc/client/grpc_client'
require_relative 'grpc/generated/secret_detection_pb'
require_relative 'grpc/generated/secret_detection_services_pb'

module Gitlab
  module SecretDetection
    module GRPC
    end
  end
end
