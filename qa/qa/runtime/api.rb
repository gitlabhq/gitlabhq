require 'airborne'

module QA
  module Runtime
    module API
      class Client
        attr_reader :address

        def initialize(address = :gitlab)
          @address = address
        end

        def personal_access_token
          @personal_access_token ||= get_personal_access_token
        end

        def get_personal_access_token
          # you can set the environment variable PERSONAL_ACCESS_TOKEN
          # to use a specific access token rather than create one from the UI
          if Runtime::Env.personal_access_token
            Runtime::Env.personal_access_token
          else
            create_personal_access_token
          end
        end

        private

        def create_personal_access_token
          Runtime::Browser.visit(@address, Page::Main::Login) do
            Page::Main::Login.act { sign_in_using_credentials }
            Factory::Resource::PersonalAccessToken.fabricate!.access_token
          end
        end
      end

      class Request
        API_VERSION = 'v4'.freeze

        def initialize(api_client, path, personal_access_token: nil)
          personal_access_token ||= api_client.personal_access_token
          request_path = request_path(path, personal_access_token: personal_access_token)
          @session_address = Runtime::Address.new(api_client.address, request_path)
        end

        def url
          @session_address.address
        end

        # Prepend a request path with the path to the API
        #
        # path - Path to append
        #
        # Examples
        #
        #   >> request_path('/issues')
        #   => "/api/v4/issues"
        #
        #   >> request_path('/issues', personal_access_token: 'sometoken)
        #   => "/api/v4/issues?private_token=..."
        #
        # Returns the relative path to the requested API resource
        def request_path(path, version: API_VERSION, personal_access_token: nil, oauth_access_token: nil)
          full_path = File.join('/api', version, path)

          if oauth_access_token
            query_string = "access_token=#{oauth_access_token}"
          elsif personal_access_token
            query_string = "private_token=#{personal_access_token}"
          end

          if query_string
            full_path << (path.include?('?') ? '&' : '?')
            full_path << query_string
          end

          full_path
        end
      end
    end
  end
end
