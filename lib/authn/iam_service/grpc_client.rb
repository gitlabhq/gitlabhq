# frozen_string_literal: true

module Authn
  module IamService
    class GrpcClient < BaseClient
      RequestError = Class.new(StandardError)

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
        reject_consent_challenge: ::Gitlab::Iam::Auth::V1::ConsentServiceRejectRequest
      }.freeze

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
        else raise ArgumentError, "Unknown gRPC method: #{method_name}"
        end
      rescue Authn::IamAuthService::ConfigurationError => e
        raise RequestError, e.message
      rescue GRPC::BadStatus => e
        Gitlab::ErrorTracking.track_exception(e)
        raise RequestError, 'Failed to connect to IAM service'
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

      def grpc_address
        Authn::IamAuthService.grpc_address
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
