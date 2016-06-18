module Gitlab
  module GithubImport
    class Client
      GITHUB_SAFE_REMAINING_REQUESTS = 100
      GITHUB_SAFE_SLEEP_TIME = 500

      attr_reader :client, :api

      def initialize(access_token)
        @client = ::OAuth2::Client.new(
          config.app_id,
          config.app_secret,
          github_options.merge(ssl: { verify: config['verify_ssl'] })
        )

        if access_token
          ::Octokit.auto_paginate = false

          @api = ::Octokit::Client.new(
            access_token: access_token,
            api_endpoint: github_options[:site],
            connection_options: {
              ssl: { verify: config['verify_ssl'] }
            }
          )
        end
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
          request { api.send(method, *args, &block) }
        else
          super(method, *args, &block)
        end
      end

      def respond_to?(method)
        api.respond_to?(method) || super
      end

      private

      def config
        Gitlab.config.omniauth.providers.find { |provider| provider.name == "github" }
      end

      def github_options
        config["args"]["client_options"].deep_symbolize_keys
      end

      def rate_limit
        api.rate_limit!
      end

      def rate_limit_exceed?
        rate_limit.remaining <= GITHUB_SAFE_REMAINING_REQUESTS
      end

      def rate_limit_sleep_time
        rate_limit.resets_in + GITHUB_SAFE_SLEEP_TIME
      end

      def request
        sleep rate_limit_sleep_time if rate_limit_exceed?

        data = yield

        last_response = api.last_response

        while last_response.rels[:next]
          sleep rate_limit_sleep_time if rate_limit_exceed?
          last_response = last_response.rels[:next].get
          data.concat(last_response.data) if last_response.data.is_a?(Array)
        end

        data
      end
    end
  end
end
