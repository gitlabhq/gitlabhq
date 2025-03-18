# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dependency Proxy (JavaScript fixtures)', feature_category: :container_registry do
  include JavaScriptFixturesHelpers

  describe GraphQL::Query, type: :request do
    include GraphqlHelpers

    let_it_be(:group) { create(:group, path: 'dependency-proxy-group') }
    let_it_be(:user) { create(:user) }

    let(:variables) do
      {
        input: {
          groupPath: group.full_path,
          identity: 'foobar',
          secret: 'secret'
        }
      }
    end

    before do
      stub_config(dependency_proxy: { enabled: true })
    end

    describe 'Docker Hub authentication for group settings' do
      base_path = 'packages_and_registries/settings/group/graphql'
      update_docker_hub_credentials_mutation_path =
        "#{base_path}/mutations/update_docker_hub_credentials.mutation.graphql"

      let(:mutation) { get_graphql_query_as_string(update_docker_hub_credentials_mutation_path) }

      context 'when user does not have access to the group' do
        it "graphql/#{update_docker_hub_credentials_mutation_path}.server_errors.json" do
          post_graphql(
            mutation,
            current_user: user,
            variables: variables
          )

          expect_graphql_errors_to_include(
            "The resource that you are attempting to access does not exist " \
              "or you don't have permission to perform this action"
          )
        end
      end

      context 'when user has access to the group &' do
        before_all do
          group.add_owner(user)
        end

        describe 'updates settings' do
          context 'when there are no errors' do
            it "graphql/#{update_docker_hub_credentials_mutation_path}.json" do
              variables[:input][:enabled] = true

              post_graphql(
                mutation,
                current_user: user,
                variables: variables
              )

              expect_graphql_errors_to_be_empty
            end
          end

          context 'when there are field errors' do
            it "graphql/#{update_docker_hub_credentials_mutation_path}.field_errors.json" do
              variables[:input][:secret] = ''

              post_graphql(
                mutation,
                current_user: user,
                variables: variables
              )

              expect(graphql_data_at('updateDependencyProxySettings', 'errors'))
                .to include("Secret can't be blank")
            end
          end
        end
      end
    end
  end
end
