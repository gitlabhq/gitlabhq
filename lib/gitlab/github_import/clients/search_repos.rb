# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Clients
      module SearchRepos
        def search_repos_by_name_graphql(name, options = {})
          with_retry do
            octokit.post(
              '/graphql',
              { query: graphql_search_repos_body(name, options) }.to_json
            ).to_h
          end
        end

        def search_repos_by_name(name, options = {})
          with_retry do
            octokit.search_repositories(
              search_repos_query(str: name, type: :name),
              options
            ).to_h
          end
        end

        private

        def graphql_search_repos_body(name, options)
          query = search_repos_query(str: name, type: :name)
          query = "query: \"#{query}\""
          first = options[:first].present? ? ", first: #{options[:first]}" : ''
          after = options[:after].present? ? ", after: \"#{options[:after]}\"" : ''
          <<-TEXT
          {
              search(type: REPOSITORY, #{query}#{first}#{after}) {
                  nodes {
                      __typename
                      ... on Repository {
                          id: databaseId
                          name
                          full_name: nameWithOwner
                          owner { login }
                      }
                  }
                  pageInfo {
                      startCursor
                      endCursor
                      hasNextPage
                      hasPreviousPage
                  }
              }
          }
          TEXT
        end

        def search_repos_query(str:, type:, include_collaborations: true, include_orgs: true)
          query = "#{str} in:#{type} is:public,private user:#{octokit.user.to_h[:login]}"

          query = [query, collaborations_subquery].join(' ') if include_collaborations
          query = [query, organizations_subquery].join(' ') if include_orgs

          query
        end
      end
    end
  end
end
