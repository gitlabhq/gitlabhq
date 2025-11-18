# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline Editor (JavaScript fixtures)', feature_category: :pipeline_composition do
  include ApiHelpers
  include JavaScriptFixturesHelpers
  include GraphqlHelpers

  let_it_be(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let_it_be(:project) { create(:project, :repository, namespace: namespace) }
  let_it_be(:user) { project.first_owner }

  describe GraphQL::Query, type: :request do
    let(:content) do
      <<~YAML
        stages:
          - test
          - build

        job_test_1:
          stage: test
          script:
            - echo "test 1"

        job_test_2:
          stage: test
          script:
            - echo "test 2"

        job_build:
          stage: build
          script:
            - echo "build"
          needs:
            - job_test_1
            - job_test_2
      YAML
    end

    let(:mutation_path) { 'ci/pipeline_editor/graphql/mutations/ci_lint.mutation.graphql' }
    let(:mutation) { get_graphql_query_as_string(mutation_path) }
    let(:variables) do
      {
        projectPath: project.full_path,
        content: content,
        ref: 'master',
        dryRun: false
      }
    end

    it 'graphql/ci/pipeline_editor/graphql/mutations/ci_lint.mutation.graphql.json' do
      post_graphql(mutation, current_user: user, variables: variables)

      expect_graphql_errors_to_be_empty
    end
  end
end
