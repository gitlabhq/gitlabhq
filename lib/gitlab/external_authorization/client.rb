# frozen_string_literal: true

Excon.defaults[:ssl_verify_peer] = false

module Gitlab
  module ExternalAuthorization
    class Client
      include ExternalAuthorization::Config

      REQUEST_HEADERS = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }.freeze

      def initialize(user, label)
        @user = user
        @label = label
      end

      def request_access
        response = Gitlab::HTTP.post(
          service_url,
          post_params
        )
        ::Gitlab::ExternalAuthorization::Response.new(response)
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        raise ::Gitlab::ExternalAuthorization::RequestFailed, e
      end

      private

      def allow_local_requests?
        Gitlab::CurrentSettings.allow_local_requests_from_system_hooks?
      end

      def post_params
        params = { headers: REQUEST_HEADERS,
                   body: body.to_json,
                   connect_timeout: timeout,
                   read_timeout: timeout,
                   write_timeout: timeout,
                   allow_local_requests: allow_local_requests? }

        if has_tls?
          params[:client_cert_data] = client_cert
          params[:client_key_data] = client_key
          params[:client_key_pass] = client_key_pass
        end

        params
      end

      def body
        @body ||= begin
          body = {
            user_identifier: @user.email,
            project_classification_label: @label,
            identities: @user.identities.map { |identity| { provider: identity.provider, extern_uid: identity.extern_uid } }
          }

          if @user.ldap_identity
            body[:user_ldap_dn] = @user.ldap_identity.extern_uid
          end

          body
        end
      end
    end
  end
end
