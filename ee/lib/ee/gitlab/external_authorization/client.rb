module EE
  module Gitlab
    module ExternalAuthorization
      class Client
        REQUEST_HEADERS = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }.freeze
        TIMEOUT = 0.5

        def self.build(user, label)
          new(
            ::EE::Gitlab::ExternalAuthorization.service_url,
            user,
            label
          )
        end

        def initialize(url, user, label)
          @url, @user, @label = url, user, label
        end

        def request_access
          response = Excon.post(
            @url,
            headers: REQUEST_HEADERS,
            body: body.to_json,
            connect_timeout: TIMEOUT,
            read_timeout: TIMEOUT,
            write_timeout: TIMEOUT
          )
          EE::Gitlab::ExternalAuthorization::Response.new(response)
        rescue Excon::Error => e
          raise EE::Gitlab::ExternalAuthorization::RequestFailed.new(e)
        end

        private

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
