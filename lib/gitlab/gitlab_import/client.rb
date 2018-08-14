module Gitlab
  module GitlabImport
    class Client
      attr_reader :client, :api

      PER_PAGE = 100

      def initialize(access_token)
        @client = ::OAuth2::Client.new(
          config.app_id,
          config.app_secret,
          gitlab_options
        )

        if access_token
          @api = OAuth2::AccessToken.from_hash(@client, access_token: access_token)
        end
      end

      def authorize_url(redirect_uri)
        client.auth_code.authorize_url({
          redirect_uri: redirect_uri,
          scope: "api"
        })
      end

      def get_token(code, redirect_uri)
        client.auth_code.get_token(code, redirect_uri: redirect_uri).token
      end

      def user
        api.get("/api/v4/user").parsed
      end

      def issues(project_identifier, **kwargs)
        lazy_page_iterator(**kwargs) do |page, per_page|
          api.get("/api/v4/projects/#{project_identifier}/issues?per_page=#{per_page}&page=#{page}").parsed
        end
      end

      def issue_comments(project_identifier, issue_id, **kwargs)
        lazy_page_iterator(**kwargs) do |page, per_page|
          api.get("/api/v4/projects/#{project_identifier}/issues/#{issue_id}/notes?per_page=#{per_page}&page=#{page}").parsed
        end
      end

      def project(id)
        api.get("/api/v4/projects/#{id}").parsed
      end

      def projects(**kwargs)
        lazy_page_iterator(**kwargs) do |page, per_page|
          api.get("/api/v4/projects?per_page=#{per_page}&page=#{page}&simple=true&membership=true").parsed
        end
      end

      private

      def lazy_page_iterator(starting_page: 1, page_limit: nil, per_page: PER_PAGE)
        Enumerator.new do |y|
          page = starting_page
          page_limit = (starting_page - 1) + page_limit if page_limit

          loop do
            items = yield(page, per_page)

            items.each do |item|
              y << item
            end

            break if items.empty? || items.size < per_page || (page_limit && page >= page_limit)

            page += 1
          end
        end
      end

      def config
        Gitlab::Auth::OAuth::Provider.config_for('gitlab')
      end

      def gitlab_options
        OmniAuth::Strategies::GitLab.default_options[:client_options].to_h.symbolize_keys
      end
    end
  end
end
