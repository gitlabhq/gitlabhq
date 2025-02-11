# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelinesController, '(JavaScript fixtures)', type: :controller, feature_category: :pipeline_composition do
  include ApiHelpers
  include GraphqlHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let_it_be(:project) { create(:project, :repository, namespace: namespace, path: 'pipelines-project') }
  let_it_be(:commit_without_author) { RepoHelpers.another_sample_commit }

  let!(:pipeline_without_author) { create(:ci_pipeline, project: project, sha: commit_without_author.id) }
  let!(:test_stage_no_author) { create(:ci_stage, name: 'test', pipeline: pipeline_without_author, project: project) }
  let!(:build_pipeline_without_author) do
    create(:ci_build, pipeline: pipeline_without_author, ci_stage: test_stage_no_author)
  end

  let_it_be(:pipeline_without_commit) { create(:ci_pipeline, status: :success, project: project, sha: '0000') }
  let!(:test_stage_no_commit) do
    create(:ci_stage, name: 'test', pipeline: pipeline_without_commit, project: pipeline_without_commit.project)
  end

  let!(:build_pipeline_without_commit) do
    create(:ci_build, pipeline: pipeline_without_commit, ci_stage: test_stage_no_commit)
  end

  let(:commit) { create(:commit, project: project) }
  let(:user) { create(:user, developer_of: project, email: commit.author_email) }
  let!(:pipeline) { create(:ci_pipeline, :with_test_reports, project: project, sha: commit.id, user: user) }

  let!(:build_stage) { create(:ci_stage, name: 'build', pipeline: pipeline, project: pipeline.project) }
  let!(:deploy_stage) { create(:ci_stage, name: 'deploy', pipeline: pipeline, project: pipeline.project) }
  let!(:test_stage) { pipeline.stage('test') }

  let!(:build_success) { create(:ci_build, pipeline: pipeline, ci_stage: build_stage) }
  let!(:build_test) { create(:ci_build, pipeline: pipeline, ci_stage: test_stage) }
  let!(:build_deploy_failed) { create(:ci_build, status: :failed, pipeline: pipeline, ci_stage: deploy_stage) }

  let(:bridge) { create(:ci_bridge, pipeline: pipeline) }
  let(:retried_bridge) { create(:ci_bridge, :retried, pipeline: pipeline) }

  let(:downstream_pipeline) { create(:ci_pipeline, :with_job) }
  let(:retried_downstream_pipeline) { create(:ci_pipeline, :with_job) }
  let!(:ci_sources_pipeline) { create(:ci_sources_pipeline, pipeline: downstream_pipeline, source_job: bridge) }
  let!(:retried_ci_sources_pipeline) do
    create(:ci_sources_pipeline, pipeline: retried_downstream_pipeline, source_job: retried_bridge)
  end

  before do
    sign_in(user)
    project.add_developer(user)
  end

  it 'pipelines/pipelines.json' do
    get :index, params: {
      namespace_id: namespace,
      project_id: project
    }, format: :json

    expect(response).to be_successful
  end

  it "pipelines/test_report.json" do
    get :test_report, params: {
      namespace_id: namespace,
      project_id: project,
      id: pipeline.id
    }, format: :json

    expect(response).to be_successful
  end

  describe GraphQL::Query, type: :request do
    fixtures_path = 'graphql/pipelines/'
    let(:base_pipeline) { create(:ci_pipeline, project: project, sha: '0000') }

    def queries
      {
        actions: get_graphql_query_as_string(
          "ci/pipelines_page/graphql/queries/get_pipeline_actions.query.graphql"
        ),
        downstream_jobs: get_graphql_query_as_string(
          "ci/pipeline_mini_graph/graphql/queries/get_downstream_pipeline_jobs.query.graphql"
        ),
        iid: get_graphql_query_as_string(
          "ci/pipeline_editor/graphql/queries/get_pipeline_iid.query.graphql"
        ),
        summary: get_graphql_query_as_string(
          "ci/common/pipeline_summary/graphql/queries/get_pipeline_summary.query.graphql"
        )
      }
    end

    it "#{fixtures_path}get_pipeline_actions.query.graphql.json" do
      stages = {
        build: create(:ci_stage, name: 'build', pipeline: base_pipeline, project: base_pipeline.project),
        test: create(:ci_stage, name: 'test', pipeline: base_pipeline, project: base_pipeline.project)
      }

      create(:ci_build, :scheduled, pipeline: base_pipeline, ci_stage: stages[:test])
      create(:ci_build, :manual, pipeline: base_pipeline, ci_stage: stages[:build])
      create(:ci_build, :manual, :skipped, pipeline: base_pipeline, ci_stage: stages[:build])

      post_graphql(
        queries[:actions],
        current_user: user,
        variables: { fullPath: project.full_path, iid: base_pipeline.iid }
      )

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}get_downstream_pipeline_jobs.query.graphql.json" do
      stage = create(:ci_stage, name: 'test', pipeline: base_pipeline, project: base_pipeline.project)
      create(:ci_build, pipeline: base_pipeline, ci_stage: stage, name: 'test_job')
      create(:ci_build, pipeline: base_pipeline, ci_stage: stage, name: 'another_test_job')

      post_graphql(
        queries[:downstream_jobs],
        current_user: user,
        variables: { fullPath: project.full_path, iid: base_pipeline.iid }
      )

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}get_pipeline_iid.query.graphql.json" do
      post_graphql(
        queries[:iid],
        current_user: user,
        variables: { fullPath: project.full_path, sha: commit.sha }
      )

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}get_pipeline_summary.query.graphql.json" do
      commit = create(:commit, project: project)
      base_pipeline.update!(sha: commit.id, user: user, finished_at: 1.hour.ago)

      post_graphql(
        queries[:summary],
        current_user: user,
        variables: { fullPath: project.full_path, iid: base_pipeline.iid, includeCommitInfo: true }
      )

      expect_graphql_errors_to_be_empty
    end
  end
end
