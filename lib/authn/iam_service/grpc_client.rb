# frozen_string_literal: true

module Authn
  module IamService
    class GrpcClient
      RequestError = Class.new(StandardError)

      TIMEOUT_SECONDS = 5

      REQUEST_TYPES = {
        health: ::Auth::V1::HealthRequest,
        accept_login_challenge: ::Auth::V1::LoginServiceAcceptRequest,
        get_consent_challenge: ::Auth::V1::ConsentServiceGetRequest,
        accept_consent_challenge: ::Auth::V1::ConsentServiceAcceptRequest,
        reject_consent_challenge: ::Auth::V1::ConsentServiceRejectRequest
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
        build_stub(::Auth::V1::AuthService::Stub)
      end

      def login_stub
        build_stub(::Auth::V1::LoginService::Stub)
      end

      def consent_stub
        build_stub(::Auth::V1::ConsentService::Stub)
      end

      def build_stub(stub_class)
        address = Authn::IamAuthService.grpc_address
        stub_class.new(
          strip_scheme(address),
          channel_credentials(address),
          interceptors: [Labkit::Correlation::GRPC::ClientInterceptor.instance],
          timeout: TIMEOUT_SECONDS
        )
      end

      def channel_credentials(address)
        uri = URI(address)

        if uri.scheme == 'tls' || uri.scheme == 'dns+tls'
          GRPC::Core::ChannelCredentials.new(::Gitlab::X509::Certificate.ca_certs_bundle)
        else
          :this_channel_is_insecure
        end
      rescue URI::InvalidURIError
        :this_channel_is_insecure
      end

      def strip_scheme(address)
        address.sub(%r{^tcp://|^tls://}, '').sub(%r{^dns\+tls:}, 'dns:')
      end

      def metadata
        { Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER => Authn::IamAuthService.secret }
      end
    end
  end
end
