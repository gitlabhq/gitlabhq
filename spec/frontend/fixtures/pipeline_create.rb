# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GraphQL Pipeline Mutations', type: :request, feature_category: :pipeline_composition do
  include ApiHelpers
  include GraphqlHelpers
  include JavaScriptFixturesHelpers

  # Project setup
  let_it_be(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let_it_be(:project) { create(:project, :repository, namespace: namespace, path: 'pipelines-project') }
  let_it_be(:user) { create(:user, developer_of: project) }

  before_all do
    project.add_developer(user)
    # Ensure we have a valid repository with CI config
    project.repository.create_file(
      user,
      '.gitlab-ci.yml',
      'test:
        script: echo "test"',
      message: 'Add CI config',
      branch_name: 'main'
    )
  end

  before do
    sign_in(user)
  end

  describe GraphQL::Query do
    describe 'Pipeline Create Mutation' do
      let_it_be(:query_file) { 'create_pipeline.mutation.graphql' }
      let_it_be(:query_path) { "ci/pipeline_new/graphql/mutations/" }
      let_it_be(:create_mutation) do
        get_graphql_query_as_string("#{query_path}#{query_file}")
      end

      context 'with valid input' do
        let(:input_variables) do
          {
            input: {
              projectPath: project.full_path,
              ref: 'main',
              clientMutationId: 'test-mutation-id',
              variables: [
                {
                  key: 'var_one',
                  value: '',
                  variableType: 'ENV_VAR'
                }
              ]
            }
          }
        end

        it 'graphql/pipelines/create_pipeline.mutation.graphql.json' do
          post_graphql(create_mutation,
            current_user: user,
            variables: input_variables
          )

          expect_graphql_errors_to_be_empty
        end
      end

      context 'with empty ref' do
        let(:input_variables) do
          {
            input: {
              projectPath: project.full_path,
              ref: '',
              clientMutationId: 'test-mutation-id',
              variables: []
            }
          }
        end

        it 'graphql/pipelines/create_pipeline_error.mutation.graphql.json' do
          post_graphql(create_mutation,
            current_user: user,
            variables: input_variables
          )

          expect(graphql_data.dig('pipelineCreate', 'errors')).not_to be_empty
        end
      end
    end
  end
end
