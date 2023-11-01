# frozen_string_literal: true

module Gitlab
  module Jira
    # Gitlab JIRA HTTP client to be used with jira-ruby gem, this subclasses JIRA::HTTPClient.
    # Uses Gitlab::HTTP to make requests to JIRA REST API.
    # The parent class implementation can be found at: https://github.com/sumoheavy/jira-ruby/blob/master/lib/jira/http_client.rb
    class HttpClient < JIRA::HttpClient
      extend ::Gitlab::Utils::Override

      override :request
      def request(*args)
        result = make_request(*args)

        raise JIRA::HTTPError, result.response unless result.response.is_a?(Net::HTTPSuccess)

        result
      end

      override :make_cookie_auth_request
      def make_cookie_auth_request
        body = {
          username: @options.delete(:username),
          password: @options.delete(:password)
        }.to_json

        make_request(:post, @options[:context_path] + '/rest/auth/1/session', body, 'Content-Type' => 'application/json')
      end

      override :make_request
      def make_request(http_method, path, body = '', headers = {})
        request_params = { headers: headers }
        request_params[:body] = body if body.present?
        request_params[:headers][:Cookie] = get_cookies if options[:use_cookies]
        request_params[:base_uri] = uri.to_s
        request_params.merge!(auth_params)
        # Setting defaults here so we can also set `timeout` which prevents setting defaults in the HTTP gem's code
        request_params[:open_timeout] = options[:open_timeout] || default_timeout_for(:open_timeout)
        request_params[:read_timeout] = options[:read_timeout] || default_timeout_for(:read_timeout)
        request_params[:write_timeout] = options[:write_timeout] || default_timeout_for(:write_timeout)
        # Global timeout. Needs to be at least as high as the maximum defined in other timeouts
        request_params[:timeout] = [
          Gitlab::HTTP::DEFAULT_READ_TOTAL_TIMEOUT,
          request_params[:open_timeout],
          request_params[:read_timeout],
          request_params[:write_timeout]
        ].max

        result = Gitlab::HTTP.public_send(http_method, path, **request_params) # rubocop:disable GitlabSecurity/PublicSend
        @authenticated = result.response.is_a?(Net::HTTPOK)
        store_cookies(result) if options[:use_cookies]

        # This is needed to make response.to_s work. HTTParty::Response internal uses a Net::HTTPResponse as @response.
        # When a block is used, Net::HTTPResponse#body will be a Net::ReadAdapter instead of a String.
        # In this case HTTParty::Response.to_s will default to inspecting the Net::HTTPResponse class instead
        # of returning the content of body.
        # See https://github.com/jnunemaker/httparty/blob/v0.18.1/lib/httparty/response.rb#L86-L92
        # See https://github.com/ruby/net-http/blob/v0.1.1/lib/net/http/response.rb#L346-L350
        result.response.body = result.body

        result
      end

      private

      def default_timeout_for(param)
        Gitlab::HTTP::DEFAULT_TIMEOUT_OPTIONS[param]
      end

      def auth_params
        return {} unless @options[:username] && @options[:password]

        {
          basic_auth: {
            username: @options[:username],
            password: @options[:password]
          }
        }
      end

      def get_cookies
        cookie_array = @cookies.values.map { |cookie| "#{cookie.name}=#{cookie.value[0]}" }
        cookie_array += Array(@options[:additional_cookies]) if @options.key?(:additional_cookies)
        cookie_array.join('; ') if cookie_array.any?
      end
    end
  end
end
