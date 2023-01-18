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
          search_query = search_repos_query(name, options)

          with_retry do
            octokit.search_repositories(search_query, options).to_h
          end
        end

        private

        def graphql_search_repos_body(name, options)
          query = search_repos_query(name, options)
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

        def search_repos_query(string, options = {})
          base = "#{string} in:name is:public,private"

          case options[:relation_type]
          when 'organization' then organization_repos_query(base, options)
          when 'collaborated' then collaborated_repos_query(base)
          when 'owned' then owned_repos_query(base)
          # TODO: remove after https://gitlab.com/gitlab-org/gitlab/-/issues/385113 get done
          else legacy_all_repos_query(base)
          end
        end

        def organization_repos_query(search_string, options)
          "#{search_string} org:#{options[:organization_login]}"
        end

        def collaborated_repos_query(search_string)
          "#{search_string} #{collaborations_subquery}"
        end

        def owned_repos_query(search_string)
          "#{search_string} user:#{octokit.user.to_h[:login]}"
        end

        def legacy_all_repos_query(search_string)
          [
            search_string,
            "user:#{octokit.user.to_h[:login]}",
            collaborations_subquery,
            organizations_subquery
          ].join(' ')
        end

        def collaborations_subquery
          each_object(:repos, nil, { affiliation: 'collaborator' })
            .map { |repo| "repo:#{repo[:full_name]}" }
            .join(' ')
        end

        def organizations_subquery
          each_object(:organizations)
            .map { |org| "org:#{org[:login]}" }
            .join(' ')
        end
      end
    end
  end
end
