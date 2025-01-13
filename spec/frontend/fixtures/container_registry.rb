# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Container registry (JavaScript fixtures)', feature_category: :container_registry do
  include GraphqlHelpers
  include JavaScriptFixturesHelpers

  describe GraphQL::Query, type: :request do
    let_it_be(:group) { create(:group, path: 'container-registry-group') }
    let_it_be(:project) { create(:project, group: group, path: 'container-registry-project') }
    let_it_be(:owner) { create(:user) }
    let_it_be(:user) { create(:user) }

    before_all do
      project.add_owner(owner)
    end

    describe 'Protected container image tags' do
      base_path = 'packages_and_registries/settings/project/graphql'
      project_container_protection_tag_rules_query_path =
        "#{base_path}/queries/get_container_protection_tag_rules.query.graphql"
      delete_container_protection_tag_rule_mutation_path =
        "#{base_path}/mutations/delete_container_protection_tag_rule.mutation.graphql"

      context 'when user does not have access to the project' do
        it "graphql/#{project_container_protection_tag_rules_query_path}.null_project.json" do
          query = get_graphql_query_as_string(project_container_protection_tag_rules_query_path)

          post_graphql(query, current_user: user, variables: { projectPath: project.full_path, first: 5 })

          expect_graphql_errors_to_be_empty
        end
      end

      context 'when user has access to the project &' do
        context 'with no tag protection rules' do
          it "graphql/#{project_container_protection_tag_rules_query_path}.empty_rules.json" do
            query = get_graphql_query_as_string(project_container_protection_tag_rules_query_path)

            post_graphql(query, current_user: owner, variables: { projectPath: project.full_path, first: 5 })

            expect_graphql_errors_to_be_empty
          end
        end

        context 'with tag protection rules' do
          let_it_be(:container_protection_tag_rule) do
            create(:container_registry_protection_tag_rule,
              project: project,
              minimum_access_level_for_push: Gitlab::Access::MAINTAINER,
              minimum_access_level_for_delete: Gitlab::Access::OWNER
            )
          end

          it "graphql/#{project_container_protection_tag_rules_query_path}.json" do
            query = get_graphql_query_as_string(project_container_protection_tag_rules_query_path)

            post_graphql(query, current_user: owner, variables: { projectPath: project.full_path, first: 5 })

            expect_graphql_errors_to_be_empty
          end
        end

        context 'when there are no errors deleting a rule' do
          let_it_be(:container_protection_tag_rule) do
            create(:container_registry_protection_tag_rule,
              project: project,
              minimum_access_level_for_push: Gitlab::Access::MAINTAINER,
              minimum_access_level_for_delete: Gitlab::Access::OWNER
            )
          end

          it "graphql/#{delete_container_protection_tag_rule_mutation_path}.json" do
            mutation = get_graphql_query_as_string(delete_container_protection_tag_rule_mutation_path)

            post_graphql(
              mutation,
              current_user: owner,
              variables: {
                input: {
                  id: "gid://gitlab/ContainerRegistry::Protection::TagRule/#{container_protection_tag_rule.id}"
                }
              }
            )

            expect_graphql_errors_to_be_empty
          end
        end

        context 'when there are errors deleting a rule' do
          it "graphql/#{delete_container_protection_tag_rule_mutation_path}.errors.json" do
            mutation = get_graphql_query_as_string(delete_container_protection_tag_rule_mutation_path)

            post_graphql(
              mutation,
              current_user: owner,
              variables: {
                input: {
                  id: 'gid://gitlab/ContainerRegistry::Protection::TagRule/non-existent'
                }
              }
            )

            expect_graphql_errors_to_include(
              "The resource that you are attempting to access does not exist or " \
                "you don't have permission to perform this action"
            )
          end
        end
      end
    end
  end
end
