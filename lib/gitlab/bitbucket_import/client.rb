module Gitlab
  module BitbucketImport
    class Client
      class Unauthorized < StandardError; end

      attr_reader :consumer, :api

      def initialize(access_token = nil, access_token_secret = nil)
        @consumer = ::OAuth::Consumer.new(
          config.app_id,
          config.app_secret,
          bitbucket_options
        )

        if access_token && access_token_secret
          @api = ::OAuth::AccessToken.new(@consumer, access_token, access_token_secret)
        end
      end

      def request_token(redirect_uri)
        request_token = consumer.get_request_token(oauth_callback: redirect_uri)

        {
          oauth_token:              request_token.token,
          oauth_token_secret:       request_token.secret,
          oauth_callback_confirmed: request_token.callback_confirmed?.to_s
        }
      end

      def authorize_url(request_token, redirect_uri)
        request_token = ::OAuth::RequestToken.from_hash(consumer, request_token) if request_token.is_a?(Hash)

        if request_token.callback_confirmed?
          request_token.authorize_url
        else
          request_token.authorize_url(oauth_callback: redirect_uri)
        end
      end

      def get_token(request_token, oauth_verifier, redirect_uri)
        request_token = ::OAuth::RequestToken.from_hash(consumer, request_token) if request_token.is_a?(Hash)

        if request_token.callback_confirmed?
          request_token.get_access_token(oauth_verifier: oauth_verifier)
        else
          request_token.get_access_token(oauth_callback: redirect_uri)
        end
      end

      def user
        JSON.parse(get("/api/1.0/user").body)
      end

      def issues(project_identifier)
        all_issues = []
        offset = 0
        per_page = 50  # Maximum number allowed by Bitbucket
        index = 0

        begin
          issues = JSON.parse(get(issue_api_endpoint(project_identifier, per_page, offset)).body)
          # Find out how many total issues are present
          total = issues["count"] if index == 0
          all_issues.concat(issues["issues"])
          offset += issues["issues"].count
          index += 1
        end while all_issues.count < total

        all_issues
      end

      def issue_comments(project_identifier, issue_id)
        comments = JSON.parse(get("/api/1.0/repositories/#{project_identifier}/issues/#{issue_id}/comments").body)
        comments.sort_by { |comment| comment["utc_created_on"] }
      end

      def project(project_identifier)
        JSON.parse(get("/api/1.0/repositories/#{project_identifier}").body)
      end

      def find_deploy_key(project_identifier, key)
        JSON.parse(get("/api/1.0/repositories/#{project_identifier}/deploy-keys").body).find do |deploy_key|
          deploy_key["key"].chomp == key.chomp
        end
      end

      def add_deploy_key(project_identifier, key)
        deploy_key = find_deploy_key(project_identifier, key)
        return if deploy_key

        JSON.parse(api.post("/api/1.0/repositories/#{project_identifier}/deploy-keys", key: key, label: "GitLab import key").body)
      end

      def delete_deploy_key(project_identifier, key)
        deploy_key = find_deploy_key(project_identifier, key)
        return unless deploy_key

        api.delete("/api/1.0/repositories/#{project_identifier}/deploy-keys/#{deploy_key["pk"]}").code == "204"
      end

      def projects
        JSON.parse(get("/api/1.0/user/repositories").body).select { |repo| repo["scm"] == "git" }
      end

      def incompatible_projects
        JSON.parse(get("/api/1.0/user/repositories").body).reject { |repo| repo["scm"] == "git" }
      end

      private

      def get(url)
        response = api.get(url)
        raise Unauthorized if (400..499).include?(response.code.to_i)

        response
      end

      def issue_api_endpoint(project_identifier, per_page, offset)
        "/api/1.0/repositories/#{project_identifier}/issues?sort=utc_created_on&limit=#{per_page}&start=#{offset}"
      end

      def config
        Gitlab.config.omniauth.providers.find { |provider| provider.name == "bitbucket"}
      end

      def bitbucket_options
        OmniAuth::Strategies::Bitbucket.default_options[:client_options].symbolize_keys
      end
    end
  end
end
