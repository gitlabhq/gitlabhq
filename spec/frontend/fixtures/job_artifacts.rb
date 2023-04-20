# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Job Artifacts (GraphQL fixtures)' do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers

    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:user) { create(:user) }

    job_artifacts_query_path = 'ci/artifacts/graphql/queries/get_job_artifacts.query.graphql'

    it "graphql/#{job_artifacts_query_path}.json" do
      create(:ci_build, :failed, :artifacts, :trace_artifact, pipeline: pipeline)
      create(:ci_build, :success, :artifacts, :trace_artifact, pipeline: pipeline)

      query = get_graphql_query_as_string(job_artifacts_query_path)

      post_graphql(query, current_user: user, variables: { projectPath: project.full_path })

      expect_graphql_errors_to_be_empty
    end
  end
end
