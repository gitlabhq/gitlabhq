# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "GraphQL Pipeline details", '(JavaScript fixtures)', type: :request, feature_category: :pipeline_composition do
  include ApiHelpers
  include GraphqlHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:admin) { project.first_owner }
  let_it_be(:commit) { create(:commit, project: project) }
  let_it_be(:pipeline) do
    create(:ci_pipeline, project: project, sha: commit.id, ref: 'master', user: admin, status: :success)
  end

  let_it_be(:build_success) do
    create(:ci_build, :dependent, name: 'build_my_app', pipeline: pipeline, stage: 'build', status: :success)
  end

  let_it_be(:build_test) { create(:ci_build, :dependent, name: 'test_my_app', pipeline: pipeline, stage: 'test') }
  let_it_be(:build_deploy_failed) do
    create(:ci_build, :dependent, name: 'deploy_my_app', status: :failed, pipeline: pipeline, stage: 'deploy')
  end

  let_it_be(:bridge) { create(:ci_bridge, pipeline: pipeline) }

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
