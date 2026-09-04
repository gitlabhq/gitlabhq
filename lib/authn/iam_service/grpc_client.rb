# frozen_string_literal: true

module Authn
  module IamService
    class GrpcClient < BaseClient
      # Carries a machine-readable reason so callers can branch on the failure
      # (e.g. tell a missing client apart from a real outage) without parsing the
      # message text. The message stays diagnostic (it includes the raw gRPC
      # status) for logs and Sentry.
      class RequestError < StandardError
        attr_reader :reason

        def initialize(message, reason: :unknown)
          @reason = reason
          super(message)
        end
      end

      # Maps the gRPC statuses these RPCs can return to a machine-readable reason
      # for callers to translate. Keyed by the integer gRPC status code
      # (GRPC::BadStatus#code); unlisted statuses fall back to :unknown.
      ERROR_REASONS = {
        GRPC::Core::StatusCodes::NOT_FOUND => :not_found,
        GRPC::Core::StatusCodes::ALREADY_EXISTS => :already_exists,
        GRPC::Core::StatusCodes::INVALID_ARGUMENT => :invalid_request,
        GRPC::Core::StatusCodes::PERMISSION_DENIED => :permission_denied,
        GRPC::Core::StatusCodes::UNAUTHENTICATED => :unauthenticated,
        GRPC::Core::StatusCodes::UNAVAILABLE => :unavailable,
        GRPC::Core::StatusCodes::DEADLINE_EXCEEDED => :timeout
      }.freeze

      TIMEOUT_SECONDS = 5

      # Workaround: the GATE sandbox Envoy gateway requires this header to route
      # gRPC traffic to the IAM backend. Harmless when sent to non-Envoy endpoints.
      # TODO: remove when direct gRPC routing replaces the Envoy header-based routing.
      ROUTING_HEADER = 'x-gitlab-svc'
      ROUTING_HEADER_VALUE = 'iam-auth-grpc'

      REQUEST_TYPES = {
        health: ::Gitlab::Iam::Auth::V1::HealthRequest,
        accept_login_challenge: ::Gitlab::Iam::Auth::V1::LoginServiceAcceptRequest,
        get_consent_challenge: ::Gitlab::Iam::Auth::V1::ConsentServiceGetRequest,
        accept_consent_challenge: ::Gitlab::Iam::Auth::V1::ConsentServiceAcceptRequest,
        reject_consent_challenge: ::Gitlab::Iam::Auth::V1::ConsentServiceRejectRequest,
        create_oauth_application: ::Gitlab::Iam::Auth::V1::InternalOAuthClientsServiceCreateClientRequest,
        get_oauth_application: ::Gitlab::Iam::Auth::V1::InternalOAuthClientsServiceGetClientRequest,
        delete_oauth_application: ::Gitlab::Iam::Auth::V1::InternalOAuthClientsServiceDeleteClientRequest
      }.freeze

      # Only RequestError carries a machine-readable reason; anything else falls back to the class name.
      def self.error_label(error)
        return error.reason.to_s if error.is_a?(RequestError)

        error.class.name
      end

      def health(**kwargs)
        call(:health, kwargs)
      end

      def accept_login_challenge(**kwargs)
        call(:accept_login_challenge, kwargs)
      end

      def get_consent_challenge(**kwargs)
        call(:get_consent_challenge, kwargs)
      end

      def accept_consent_challenge(**kwargs)
        call(:accept_consent_challenge, kwargs)
      end

      def reject_consent_challenge(**kwargs)
        call(:reject_consent_challenge, kwargs)
      end

      def create_oauth_application(**kwargs)
        call(:create_oauth_application, kwargs)
      end

      def get_oauth_application(**kwargs)
        call(:get_oauth_application, kwargs)
      end

      def delete_oauth_application(**kwargs)
        call(:delete_oauth_application, kwargs)
      end

      private

      def call(method_name, kwargs)
        request = REQUEST_TYPES.fetch(method_name).new(**kwargs)
        options = { metadata: metadata }

        case method_name
        when :health then stub.health(request, **options)
        when :accept_login_challenge then login_stub.accept(request, **options)
        when :get_consent_challenge then consent_stub.get(request, **options)
        when :accept_consent_challenge then consent_stub.accept(request, **options)
        when :reject_consent_challenge then consent_stub.reject(request, **options)
        when :create_oauth_application then oauth_clients_stub.create_client(request, **options)
        when :get_oauth_application then oauth_clients_stub.get_client(request, **options)
        when :delete_oauth_application then oauth_clients_stub.delete_client(request, **options)
        else raise ArgumentError, "Unknown gRPC method: #{method_name}"
        end
      rescue Authn::IamAuthService::ConfigurationError => e
        Gitlab::ErrorTracking.track_exception(e)
        raise RequestError.new('IAM auth service is not configured', reason: :unavailable)
      rescue GRPC::BadStatus => e
        Gitlab::ErrorTracking.track_exception(e)
        raise RequestError.new(
          "IAM service request failed: #{e.code}",
          reason: ERROR_REASONS.fetch(e.code, :unknown)
        )
      end

      def stub
        build_stub(::Gitlab::Iam::Auth::V1::AuthService::Stub, grpc_address, timeout: TIMEOUT_SECONDS)
      end

      def login_stub
        build_stub(::Gitlab::Iam::Auth::V1::LoginService::Stub, grpc_address, timeout: TIMEOUT_SECONDS)
      end

      def consent_stub
        build_stub(::Gitlab::Iam::Auth::V1::ConsentService::Stub, grpc_address, timeout: TIMEOUT_SECONDS)
      end

      def oauth_clients_stub
        build_stub(::Gitlab::Iam::Auth::V1::InternalOAuthClientsService::Stub, grpc_address, timeout: TIMEOUT_SECONDS)
      end

      def grpc_address
        Authn::IamAuthService.grpc_address
      end

      def secure_transport?
        Authn::IamAuthService.grpc_secure?
      end

      def metadata
        { ROUTING_HEADER => ROUTING_HEADER_VALUE }
      end

      def service_token_credentials
        {
          header: Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER,
          token: Authn::IamAuthService.secret
        }
      end
    end
  end
end
