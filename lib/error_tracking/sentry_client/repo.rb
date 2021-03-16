# frozen_string_literal: true

module ErrorTracking
  class SentryClient
    module Repo
      def repos(organization_slug)
        repos_url = repos_api_url(organization_slug)

        repos = http_get(repos_url)[:body]

        handle_mapping_exceptions do
          map_to_repos(repos)
        end
      end

      private

      def repos_api_url(organization_slug)
        repos_url = URI(url)
        repos_url.path = "/api/0/organizations/#{organization_slug}/repos/"

        repos_url
      end

      def map_to_repos(repos)
        repos.map(&method(:map_to_repo))
      end

      def map_to_repo(repo)
        Gitlab::ErrorTracking::Repo.new(
          status: repo.fetch('status'),
          integration_id: repo.fetch('integrationId'),
          project_id: repo.fetch('externalSlug')
        )
      end
    end
  end
end
