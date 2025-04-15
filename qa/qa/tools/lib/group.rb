# frozen_string_literal: true

module QA
  module Tools
    module Lib
      module Group
        include Support::API
        def fetch_group_id(api_client, name = ENV['TOP_LEVEL_GROUP_NAME'])
          group_name = name || "gitlab-e2e-sandbox-group-#{Time.now.wday + 1}"

          logger.info("Fetching group #{group_name}...")

          group_search_response = get Runtime::API::Request.new(api_client, "/groups/#{group_name}").url

          if group_search_response.code != HTTP_STATUS_OK
            logger.error("Response code #{group_search_response.code}: #{group_search_response.body}")
            exit 1 if group_search_response.code == HTTP_STATUS_UNAUTHORIZED
            return
          end

          group = parse_body(group_search_response)

          logger.warn("Top level group #{group_name} not found") if group[:id].nil?

          group[:id]
        end

        def get_group_graphql(group)
          query = <<~GRAPHQL
            query {
              group(fullPath: "#{group[:full_path]}") {
                securityPolicyProject {
                  id
                }
              }
            }
          GRAPHQL

          graphql_request(query)
        end

        def get_subgroups_graphql(group)
          query = <<~GRAPHQL
            query {
              group(fullPath: "#{group[:full_path]}") {
                descendantGroups {
                  nodes {
                    id
                    name
                    fullPath
                    securityPolicyProject {
                      id
                      name
                      fullPath
                    }
                  }
                }
              }
            }
          GRAPHQL

          graphql_request(query)
        end

        def get_group_projects_graphql(group)
          query = <<~GRAPHQL
            query {
              group(fullPath: "#{group[:full_path]}") {
                projects(includeSubgroups: true) {
                  nodes {
                    id
                    name
                    fullPath
                    securityPolicyProject {
                      id
                      name
                      fullPath
                    }
                  }
                }
              }
            }
          GRAPHQL

          graphql_request(query)
        end

        def has_security_policy_project?(group)
          response = get_group_graphql(group)
          response&.dig(:data, :group, :securityPolicyProject).present?
        end

        def subgroups_with_security_policy_projects(group)
          response = get_subgroups_graphql(group)
          subgroups = response&.dig(:data, :group, :descendantGroups, :nodes)
          subgroups.select do |subgroup|
            subgroup&.dig(:securityPolicyProject).present?
          end
        end

        def projects_with_security_policy_projects(group)
          response = get_group_projects_graphql(group)
          projects = response&.dig(:data, :group, :projects, :nodes)
          projects.select do |project|
            project&.dig(:securityPolicyProject).present?
          end
        end
      end
    end
  end
end
