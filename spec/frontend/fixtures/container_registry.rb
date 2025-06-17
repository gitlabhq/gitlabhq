# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Container registry (JavaScript fixtures)', feature_category: :container_registry do
  include ContainerRegistryHelpers
  include GraphqlHelpers
  include JavaScriptFixturesHelpers

  describe GraphQL::Query, type: :request do
    let_it_be(:group) { create(:group, path: 'container-registry-group') }
    let_it_be(:project) { create(:project, group: group, path: 'container-registry-project') }
    let_it_be(:user) { create(:user) }

    describe 'Protected container image tags' do
      base_path = 'packages_and_registries/settings/project/graphql'
      project_container_protection_tag_rules_query_path =
        "#{base_path}/queries/get_container_protection_tag_rules.query.graphql"
      create_container_protection_tag_rule_mutation_path =
        "#{base_path}/mutations/create_container_protection_tag_rule.mutation.graphql"
      delete_container_protection_tag_rule_mutation_path =
        "#{base_path}/mutations/delete_container_protection_tag_rule.mutation.graphql"
      update_container_protection_tag_rule_mutation_path =
        "#{base_path}/mutations/update_container_protection_tag_rule.mutation.graphql"

      let(:query) { get_graphql_query_as_string(project_container_protection_tag_rules_query_path) }

      let(:variables) do
        {
          projectPath: project.full_path,
          first: 5
        }
      end

      before do
        stub_gitlab_api_client_to_support_gitlab_api(supported: true)
      end

      context 'when user does not have access to the project' do
        it "graphql/#{project_container_protection_tag_rules_query_path}.null_project.json" do
          post_graphql(query, current_user: user, variables: variables)

          expect_graphql_errors_to_be_empty
        end
      end

      context 'when user has access to the project &' do
        before_all do
          project.add_owner(user)
        end

        context 'with no tag protection rules' do
          it "graphql/#{project_container_protection_tag_rules_query_path}.empty_rules.json" do
            post_graphql(query, current_user: user, variables: variables)

            expect_graphql_errors_to_be_empty
          end
        end

        context 'with tag protection rules' do
          before do
            create(:container_registry_protection_tag_rule,
              project: project,
              minimum_access_level_for_push: Gitlab::Access::MAINTAINER,
              minimum_access_level_for_delete: Gitlab::Access::OWNER
            )
          end

          it "graphql/#{project_container_protection_tag_rules_query_path}.json" do
            post_graphql(query, current_user: user, variables: variables)

            expect_graphql_errors_to_be_empty
          end
        end

        context 'with maximum number of tag protection rules' do
          before do
            5.times do |i|
              create(:container_registry_protection_tag_rule,
                project: project,
                tag_name_pattern: "v#{i + 1}.+")
            end
          end

          it "graphql/#{project_container_protection_tag_rules_query_path}.max_rules.json" do
            post_graphql(query, current_user: user, variables: variables)

            expect_graphql_errors_to_be_empty
          end
        end

        describe 'deleting a rule' do
          let(:mutation) { get_graphql_query_as_string(delete_container_protection_tag_rule_mutation_path) }

          context 'when there are no errors' do
            let_it_be(:container_protection_tag_rule) do
              create(:container_registry_protection_tag_rule,
                project: project,
                minimum_access_level_for_push: Gitlab::Access::MAINTAINER,
                minimum_access_level_for_delete: Gitlab::Access::OWNER
              )
            end

            it "graphql/#{delete_container_protection_tag_rule_mutation_path}.json" do
              post_graphql(
                mutation,
                current_user: user,
                variables: {
                  input: {
                    id: "gid://gitlab/ContainerRegistry::Protection::TagRule/#{container_protection_tag_rule.id}"
                  }
                }
              )

              expect_graphql_errors_to_be_empty
            end
          end

          context 'when there are errors' do
            it "graphql/#{delete_container_protection_tag_rule_mutation_path}.errors.json" do
              post_graphql(
                mutation,
                current_user: user,
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

        describe 'creating a rule' do
          let(:mutation) { get_graphql_query_as_string(create_container_protection_tag_rule_mutation_path) }

          let(:variables) do
            {
              input: {
                projectPath: project.full_path,
                tagNamePattern: 'v.*',
                minimumAccessLevelForPush: 'MAINTAINER',
                minimumAccessLevelForDelete: 'OWNER'
              }
            }
          end

          context 'when there are no errors' do
            it "graphql/#{create_container_protection_tag_rule_mutation_path}.json" do
              post_graphql(
                mutation,
                current_user: user,
                variables: variables
              )

              expect_graphql_errors_to_be_empty
            end
          end

          context 'when there are field errors' do
            it "graphql/#{create_container_protection_tag_rule_mutation_path}.server_errors.json" do
              variables[:input][:tagNamePattern] = ''

              post_graphql(
                mutation,
                current_user: user,
                variables: variables
              )

              expect_graphql_errors_to_include(
                "tagNamePattern can't be blank"
              )
            end
          end

          context 'when there are errors' do
            before do
              create(:container_registry_protection_tag_rule, project: project,
                tag_name_pattern: "v.*")
            end

            it "graphql/#{create_container_protection_tag_rule_mutation_path}.errors.json" do
              post_graphql(
                mutation,
                current_user: user,
                variables: variables
              )

              expect(graphql_data_at('createContainerProtectionTagRule', 'errors'))
                .to include('Tag name pattern has already been taken')
            end
          end
        end

        describe 'updating a rule' do
          let_it_be(:container_protection_tag_rule) do
            create(:container_registry_protection_tag_rule,
              project: project,
              minimum_access_level_for_push: Gitlab::Access::MAINTAINER,
              minimum_access_level_for_delete: Gitlab::Access::OWNER
            )
          end

          let(:mutation) { get_graphql_query_as_string(update_container_protection_tag_rule_mutation_path) }
          let(:variables) do
            {
              input: {
                id: "gid://gitlab/ContainerRegistry::Protection::TagRule/#{container_protection_tag_rule.id}",
                tagNamePattern: 'v.*',
                minimumAccessLevelForPush: 'MAINTAINER',
                minimumAccessLevelForDelete: 'OWNER'
              }
            }
          end

          context 'when there are no errors' do
            it "graphql/#{update_container_protection_tag_rule_mutation_path}.json" do
              mutation = get_graphql_query_as_string(update_container_protection_tag_rule_mutation_path)

              post_graphql(
                mutation,
                current_user: user,
                variables: variables
              )

              expect_graphql_errors_to_be_empty
            end
          end

          context 'when there are field errors' do
            it "graphql/#{update_container_protection_tag_rule_mutation_path}.server_errors.json" do
              variables[:input][:tagNamePattern] = ''

              post_graphql(
                mutation,
                current_user: user,
                variables: variables
              )

              expect_graphql_errors_to_include(
                "tagNamePattern can't be blank"
              )
            end
          end

          context 'when there are errors' do
            before do
              create(:container_registry_protection_tag_rule, project: project,
                tag_name_pattern: "v.*")
            end

            it "graphql/#{update_container_protection_tag_rule_mutation_path}.errors.json" do
              mutation = get_graphql_query_as_string(update_container_protection_tag_rule_mutation_path)

              post_graphql(
                mutation,
                current_user: user,
                variables: variables
              )

              expect(graphql_data_at('updateContainerProtectionTagRule', 'errors'))
                .to include('Tag name pattern has already been taken')
            end
          end
        end
      end
    end
  end
end
