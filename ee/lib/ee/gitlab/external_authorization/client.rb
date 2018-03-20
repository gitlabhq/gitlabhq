module EE
  module Gitlab
    module ExternalAuthorization
      class Client
        REQUEST_HEADERS = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }.freeze

        def self.build(user, label)
          new(
            ::EE::Gitlab::ExternalAuthorization.service_url,
            ::EE::Gitlab::ExternalAuthorization.timeout,
            user,
            label
          )
        end

        def initialize(url, timeout, user, label)
          @url, @timeout, @user, @label = url, timeout, user, label
        end

        def request_access
          response = Excon.post(
            @url,
            headers: REQUEST_HEADERS,
            body: body.to_json,
            connect_timeout: @timeout,
            read_timeout: @timeout,
            write_timeout: @timeout
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
