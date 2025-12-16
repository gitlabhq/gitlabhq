# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "GraphQL Pipeline details", '(JavaScript fixtures)', type: :request, feature_category: :pipeline_composition do
  include ApiHelpers
  include GraphqlHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:admin) { project.first_owner }

  let(:config) do
    <<~YAML
      stages:
        - build
        - test
        - deploy

      build_1:
        stage: build
        script: echo "build 1"

      build_2:
        stage: build
        script: echo "build 2"

      test_1:
        stage: test
        script: echo "test 1"
        needs: [build_1]

      test_2:
        stage: test
        script: echo "test 2"
        needs: [build_2]

      test_3:
        stage: test
        script: echo "test 3"

      deploy:
        stage: deploy
        script: echo "deploy"
        needs: [test_1]

      bridge_job:
        stage: deploy
        trigger:
          project: frontend-fixtures/triggered-project
    YAML
  end

  let(:pipeline) do
    stub_ci_pipeline_yaml_file(config)
    Ci::CreatePipelineService.new(project, admin, ref: 'master').execute(:push).payload
  end

  let(:pipeline_details_query_path) { 'app/graphql/queries/pipelines/get_pipeline_details.query.graphql' }

  it "pipelines/pipeline_details.json" do
    query = get_graphql_query_as_string(pipeline_details_query_path, with_base_path: false)

    post_graphql(query, current_user: admin, variables: { projectPath: project.full_path, iid: pipeline.iid })

    expect_graphql_errors_to_be_empty
  end

  it "pipelines/anonymous_pipeline_details.json" do
    query = get_graphql_query_as_string(pipeline_details_query_path, with_base_path: false)

    post_graphql(query, current_user: nil, variables: { projectPath: project.full_path, iid: pipeline.iid })

    expect_graphql_errors_to_be_empty
  end
end
