module Gitlab
  module GithubImport
    class Client
      attr_reader :client, :api

      def initialize(access_token)
        @client = ::OAuth2::Client.new(
          config.app_id,
          config.app_secret,
          github_options
        )

        if access_token
          ::Octokit.auto_paginate = true
          @api = ::Octokit::Client.new(access_token: access_token, api_endpoint: api_endpoint)
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
          api.send(method, *args, &block)
        else
          super(method, *args, &block)
        end
      end

      def respond_to?(method)
        api.respond_to?(method) || super
      end

      private

      def config
        Gitlab.config.omniauth.providers.find{|provider| provider.name == "github"}
      end

      def api_endpoint
        File.join(config["url"], "/api/v3/") if config["url"]
      end

      def github_options
        {
          site: config["url"] || 'https://api.github.com',
          authorize_url: '/login/oauth/authorize',
          token_url: '/login/oauth/access_token'
        }
      end
    end
  end
end
