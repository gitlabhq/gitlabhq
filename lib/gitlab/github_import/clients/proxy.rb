# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Clients
      class Proxy
        attr_reader :client

        delegate :each_object, :user, :octokit, to: :client

        REPOS_COUNT_CACHE_KEY = 'github-importer/provider-repo-count/%{type}/%{user_id}'

        def initialize(access_token)
          @client = Gitlab::GithubImport::Client.new(access_token)
        end

        def repos(search_text, options)
          fetch_repos_via_graphql(search_text, options)
        end

        def count_repos_by(relation_type, user_id)
          key = format(REPOS_COUNT_CACHE_KEY, type: relation_type, user_id: user_id)

          ::Gitlab::Cache::Import::Caching.read_integer(key, timeout: 5.minutes) ||
            fetch_and_cache_repos_count_via_graphql(relation_type, key)
        end

        private

        def fetch_repos_via_graphql(search_text, options)
          response = client.search_repos_by_name_graphql(search_text, options)
          {
            repos: response.dig(:data, :search, :nodes),
            page_info: response.dig(:data, :search, :pageInfo),
            count: response.dig(:data, :search, :repositoryCount)
          }
        end

        def fetch_and_cache_repos_count_via_graphql(relation_type, key)
          response = client.count_repos_by_relation_type_graphql(relation_type: relation_type)
          count = response.dig(:data, :search, :repositoryCount)

          ::Gitlab::Cache::Import::Caching.write(key, count, timeout: 5.minutes)
        end
      end
    end
  end
end
