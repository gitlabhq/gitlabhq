# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Clients
      class Proxy
        attr_reader :client

        def initialize(access_token, client_options)
          @client = pick_client(access_token, client_options)
        end

        def repos(search_text, pagination_options)
          return { repos: filtered(client.repos, search_text) } if use_legacy?

          if use_graphql?
            fetch_repos_via_graphql(search_text, pagination_options)
          else
            fetch_repos_via_rest(search_text, pagination_options)
          end
        end

        private

        def fetch_repos_via_rest(search_text, pagination_options)
          { repos: client.search_repos_by_name(search_text, pagination_options)[:items] }
        end

        def fetch_repos_via_graphql(search_text, pagination_options)
          response = client.search_repos_by_name_graphql(search_text, pagination_options)
          {
            repos: response.dig(:data, :search, :nodes),
            page_info: response.dig(:data, :search, :pageInfo)
          }
        end

        def pick_client(access_token, client_options)
          return Gitlab::GithubImport::Client.new(access_token) unless use_legacy?

          Gitlab::LegacyGithubImport::Client.new(access_token, **client_options)
        end

        def filtered(collection, search_text)
          return collection if search_text.blank?

          collection.select { |item| item[:name].to_s.downcase.include?(search_text) }
        end

        def use_legacy?
          Feature.disabled?(:remove_legacy_github_client)
        end

        def use_graphql?
          Feature.enabled?(:github_client_fetch_repos_via_graphql)
        end
      end
    end
  end
end
