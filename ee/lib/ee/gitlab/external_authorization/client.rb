module EE
  module Gitlab
    module ExternalAuthorization
      class Client
        include Config

        REQUEST_HEADERS = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }.freeze

        def initialize(user, label)
          @user, @label = user, label
        end

        def request_access
          response = Excon.post(
            service_url,
            post_params
          )
          EE::Gitlab::ExternalAuthorization::Response.new(response)
        rescue Excon::Error => e
          raise EE::Gitlab::ExternalAuthorization::RequestFailed.new(e)
        end

        private

        def post_params
          params = { headers: REQUEST_HEADERS,
                     body: body.to_json,
                     connect_timeout: timeout,
                     read_timeout: timeout,
                     write_timeout: timeout }

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
                        project_classification_label: @label
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
end
