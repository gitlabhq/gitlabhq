module Gitlab
  module LegacyGithubImport
    class Client
      GITHUB_SAFE_REMAINING_REQUESTS = 100
      GITHUB_SAFE_SLEEP_TIME = 500

      attr_reader :access_token, :host, :api_version

      def initialize(access_token, host: nil, api_version: 'v3')
        @access_token = access_token
        @host = host.to_s.sub(%r{/+\z}, '')
        @api_version = api_version
        @users = {}

        if access_token
          ::Octokit.auto_paginate = false
        end
      end

      def api
        @api ||= ::Octokit::Client.new(
          access_token: access_token,
          api_endpoint: api_endpoint,
          # If there is no config, we're connecting to github.com and we
          # should verify ssl.
          connection_options: {
            ssl: { verify: config ? config['verify_ssl'] : true }
          }
        )
      end

      def client
        unless config
          raise Projects::ImportService::Error,
            'OAuth configuration for GitHub missing.'
        end

        @client ||= ::OAuth2::Client.new(
          config.app_id,
          config.app_secret,
          github_options.merge(ssl: { verify: config['verify_ssl'] })
        )
      end

      def authorize_url(redirect_uri)
        client.auth_code.authorize_url({
          redirect_uri: redirect_uri,
          scope: "repo, user, user:email"
        })
      end

      def get_token(code)
        client.auth_code.get_token(code).token
      end

      def method_missing(method, *args, &block)
        if api.respond_to?(method)
          request(method, *args, &block)
        else
          super(method, *args, &block)
        end
      end

      def respond_to?(method)
        api.respond_to?(method) || super
      end

      def user(login)
        return nil unless login.present?
        return @users[login] if @users.key?(login)

        @users[login] = api.user(login)
      end

      private

      def api_endpoint
        if host.present? && api_version.present?
          "#{host}/api/#{api_version}"
        else
          github_options[:site]
        end
      end

      def config
        Gitlab::Auth::OAuth::Provider.config_for('github')
      end

      def github_options
        if config
          config["args"]["client_options"].deep_symbolize_keys
        else
          OmniAuth::Strategies::GitHub.default_options[:client_options].symbolize_keys
        end
      end

      def rate_limit
        api.rate_limit!
      # GitHub Rate Limit API returns 404 when the rate limit is
      # disabled. In this case we just want to return gracefully
      # instead of spitting out an error.
      rescue Octokit::NotFound
        nil
      end

      def has_rate_limit?
        return @has_rate_limit if defined?(@has_rate_limit)

        @has_rate_limit = rate_limit.present?
      end

      def rate_limit_exceed?
        has_rate_limit? && rate_limit.remaining <= GITHUB_SAFE_REMAINING_REQUESTS
      end

      def rate_limit_sleep_time
        rate_limit.resets_in + GITHUB_SAFE_SLEEP_TIME
      end

      def request(method, *args, &block)
        sleep rate_limit_sleep_time if rate_limit_exceed?

        data = api.__send__(method, *args) # rubocop:disable GitlabSecurity/PublicSend
        return data unless data.is_a?(Array)

        last_response = api.last_response

        if block_given?
          yield data
          # api.last_response could change while we're yielding (e.g. fetching labels for each PR)
          # so we cache our own last response
          each_response_page(last_response, &block)
        else
          each_response_page(last_response) { |page| data.concat(page) }
          data
        end
      end

      def each_response_page(last_response)
        while last_response.rels[:next]
          sleep rate_limit_sleep_time if rate_limit_exceed?
          last_response = last_response.rels[:next].get
          yield last_response.data if last_response.data.is_a?(Array)
        end
      end
    end
  end
end
