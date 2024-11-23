# frozen_string_literal: true

require 'grpc'
require 'logger'
require_relative '../../utils'
require_relative 'stream_request_enumerator'

module Gitlab
  module SecretDetection
    module GRPC
      class Client
        include Gitlab::SecretDetection::Utils::StrongMemoize

        # Time to wait for the response from the service
        REQUEST_TIMEOUT_SECONDS = 10 # 10 seconds

        def initialize(host, secure: false, compression: true, logger: Logger.new($stdout))
          @host = host
          @secure = secure
          @compression = compression
          @logger = logger
        end

        # Triggers Secret Detection service's `/Scan` gRPC endpoint. To keep it consistent with SDS gem interface,
        # this method transforms the gRPC response to +Gitlab::SecretDetection::Response+.
        # Furthermore, any errors that are raised by the service will be translated to
        # +Gitlab::SecretDetection::Response+ type by assiging a appropriate +status+ value to it.
        def run_scan(request:, auth_token:, extra_headers: {})
          with_rescued_errors do
            grpc_response = stub.scan(
              request,
              metadata: build_metadata(auth_token, extra_headers),
              deadline: request_deadline
            )

            convert_to_core_response(grpc_response)
          end
        end

        # Triggers Secret Detection service's `/ScanStream` gRPC endpoint.
        #
        # To keep it consistent with SDS gem interface, this method transforms the gRPC response to
        # +Gitlab::SecretDetection::Response+ type. Furthermore, any errors that are raised by the service will be
        # translated to +Gitlab::SecretDetection::Response+ type by assiging a appropriate +status+ value to it.
        #
        # Note: If one of the stream requests result in an error, the stream will end immediately without processing the
        # remaining requests.
        def run_scan_stream(requests:, auth_token:, extra_headers: {})
          request_stream = Gitlab::SecretDetection::GRPC::StreamRequestEnumerator.new(requests)
          results = []
          with_rescued_errors do
            stub.scan_stream(
              request_stream.each_item,
              metadata: build_metadata(auth_token, extra_headers),
              deadline: request_deadline
            ).each do |grpc_response|
              response = convert_to_core_response(grpc_response)
              if block_given?
                yield response
              else
                results << response
              end
            end
            results
          end
        end

        private

        attr_reader :secure, :host, :compression, :logger

        def stub
          Gitlab::SecretDetection::GRPC::Scanner::Stub.new(
            host,
            channel_credentials,
            channel_args:
          )
        end

        strong_memoize_attr :stub

        def channel_args
          default_options = {
            'grpc.keepalive_permit_without_calls' => 1,
            'grpc.keepalive_time_ms' => 30000, # 30 seconds
            'grpc.keepalive_timeout_ms' => 10000 # 10 seconds timeout for keepalive response
          }

          compression_options = ::GRPC::Core::CompressionOptions
                                  .new(default_algorithm: :gzip)
                                  .to_channel_arg_hash

          default_options.merge!(compression_options) if compression

          default_options.freeze
        end

        def channel_credentials
          return :this_channel_is_insecure unless secure

          certs = Gitlab::SecretDetection::Utils::X509::Certificate.ca_certs_bundle

          ::GRPC::Core::ChannelCredentials.new(certs)
        end

        def build_metadata(token, extra_headers = {})
          { 'x-sd-auth' => token }.merge!(extra_headers).freeze
        end

        def request_deadline
          Time.now + REQUEST_TIMEOUT_SECONDS
        end

        def with_rescued_errors
          yield
        rescue ::GRPC::Unauthenticated
          SecretDetection::Response.new(SecretDetection::Status::AUTH_ERROR)
        rescue ::GRPC::InvalidArgument => e
          SecretDetection::Response.new(
            SecretDetection::Status::INPUT_ERROR, nil, { message: e.details, **e.metadata }
          )
        rescue ::GRPC::Unknown, ::GRPC::BadStatus => e
          SecretDetection::Response.new(
            SecretDetection::Status::SCAN_ERROR, nil, { message: e.details }
          )
        end

        def convert_to_core_response(grpc_response)
          response = grpc_response.to_h

          SecretDetection::Response.new(
            response[:status],
            response[:results]
          )
        rescue StandardError => e
          logger.error("Failed to convert to core response: #{e}")
          SecretDetection::Response.new(SecretDetection::Status::SCAN_ERROR)
        end
      end
    end
  end
end
