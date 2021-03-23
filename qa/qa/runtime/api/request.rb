# frozen_string_literal: true

module QA
  module Runtime
    module API
      class Request
        API_VERSION = 'v4'

        def initialize(api_client, path, **query_string)
          query_string[:private_token] ||= api_client.personal_access_token unless query_string[:oauth_access_token]
          request_path = request_path(path, **query_string)
          @session_address = Runtime::Address.new(api_client.address, request_path)
        end

        def mask_url
          @session_address.address.sub(/private_token=.*/, "private_token=[****]")
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
        #   >> request_path('/issues', private_token: 'sometoken)
        #   => "/api/v4/issues?private_token=..."
        #
        # Returns the relative path to the requested API resource
        def request_path(path, version: API_VERSION, **query_string)
          full_path = if path == '/graphql'
                        ::File.join('/api', path)
                      else
                        ::File.join('/api', version, path)
                      end

          if query_string.any?
            full_path << (path.include?('?') ? '&' : '?')
            full_path << query_string.map { |k, v| "#{k}=#{CGI.escape(v)}" }.join('&')
          end

          full_path
        end
      end
    end
  end
end
