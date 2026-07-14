# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelinesController, '(JavaScript fixtures)', type: :controller, feature_category: :pipeline_composition do
  include ApiHelpers
  include GraphqlHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:namespace, freeze: false) { create(:namespace, name: 'frontend-fixtures') }
  let_it_be(:project, freeze: false) { create(:project, :repository, namespace: namespace, path: 'pipelines-project') }

  let(:commit) { create(:commit, project: project) }
  let(:user) { create(:user, developer_of: project, email: commit.author_email) }

  before do
    sign_in(user)
  end

  it 'pipelines/pipelines.json' do
    # A pipeline whose sha resolves to no commit.
    no_commit_pipeline = create(:ci_pipeline, status: :success, project: project, sha: '0000')
    no_commit_stage = create(:ci_stage, name: 'test', pipeline: no_commit_pipeline, project: project)
    create(:ci_build, pipeline: no_commit_pipeline, ci_stage: no_commit_stage)

    # A pipeline whose commit has no author.
    no_author_pipeline = create(:ci_pipeline, project: project, sha: RepoHelpers.another_sample_commit.id)
    no_author_stage = create(:ci_stage, name: 'test', pipeline: no_author_pipeline, project: project)
    create(:ci_build, pipeline: no_author_pipeline, ci_stage: no_author_stage)

    # The latest pipeline: full commit + author, three stages, and two downstream pipelines.
    pipeline = create(:ci_pipeline, :with_test_reports, project: project, sha: commit.id, user: user)
    build_stage = create(:ci_stage, name: 'build', pipeline: pipeline, project: project)
    deploy_stage = create(:ci_stage, name: 'deploy', pipeline: pipeline, project: project)
    create(:ci_build, pipeline: pipeline, ci_stage: build_stage)
    create(:ci_build, pipeline: pipeline, ci_stage: pipeline.stage('test'))
    create(:ci_build, status: :failed, pipeline: pipeline, ci_stage: deploy_stage)
    create(:ci_sources_pipeline,
      pipeline: create(:ci_pipeline, :with_job), source_job: create(:ci_bridge, pipeline: pipeline))
    create(:ci_sources_pipeline,
      pipeline: create(:ci_pipeline, :with_job), source_job: create(:ci_bridge, :retried, pipeline: pipeline))

    get :index, params: {
      namespace_id: namespace,
      project_id: project
    }, format: :json

    expect(response).to be_successful
  end

  it "pipelines/test_report.json" do
    pipeline = create(:ci_pipeline, :with_test_reports, project: project, sha: commit.id, user: user)

    get :test_report, params: {
      namespace_id: namespace,
      project_id: project,
      id: pipeline.id
    }, format: :json

    expect(response).to be_successful
  end

  describe GraphQL::Query, type: :request do
    fixtures_path = 'graphql/pipelines/'

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
        ),
        pipelines: get_graphql_query_as_string(
          "ci/pipelines_page/graphql/queries/get_pipelines.query.graphql"
        ),
        single_pipeline: get_graphql_query_as_string(
          "ci/pipelines_page/graphql/queries/get_single_pipeline.query.graphql"
        ),
        commit_pipelines: get_graphql_query_as_string(
          "ci/commit/graphql/queries/get_commit_pipelines.query.graphql"
        )
      }
    end

    it "#{fixtures_path}get_pipeline_actions.query.graphql.json" do
      pipeline = create(:ci_pipeline, project: project, sha: '0000')
      build_stage = create(:ci_stage, name: 'build', pipeline: pipeline, project: pipeline.project)
      test_stage = create(:ci_stage, name: 'test', pipeline: pipeline, project: pipeline.project)

      create(:ci_build, :scheduled, pipeline: pipeline, ci_stage: test_stage)
      create(:ci_build, :manual, pipeline: pipeline, ci_stage: build_stage)
      create(:ci_build, :manual, :skipped, pipeline: pipeline, ci_stage: build_stage)

      post_graphql(
        queries[:actions],
        current_user: user,
        variables: { fullPath: project.full_path, iid: pipeline.iid }
      )

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}get_downstream_pipeline_jobs.query.graphql.json" do
      pipeline = create(:ci_pipeline, project: project, sha: '0000')
      stage = create(:ci_stage, name: 'test', pipeline: pipeline, project: pipeline.project)
      create(:ci_build, pipeline: pipeline, ci_stage: stage, name: 'test_job')
      create(:ci_build, :retried, pipeline: pipeline, ci_stage: stage, name: 'test_job')
      create(:ci_build, pipeline: pipeline, ci_stage: stage, name: 'another_test_job')

      post_graphql(
        queries[:downstream_jobs],
        current_user: user,
        variables: { fullPath: project.full_path, iid: pipeline.iid, retried: false }
      )

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}get_pipeline_iid.query.graphql.json" do
      create(:ci_pipeline, project: project, sha: commit.id)

      post_graphql(
        queries[:iid],
        current_user: user,
        variables: { fullPath: project.full_path, sha: commit.sha }
      )

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}get_pipeline_summary.query.graphql.json" do
      pipeline = create(:ci_pipeline, project: project, sha: '0000')
      summary_commit = create(:commit, project: project)
      pipeline.update!(sha: summary_commit.id, user: user, finished_at: 1.hour.ago)

      post_graphql(
        queries[:summary],
        current_user: user,
        variables: { fullPath: project.full_path, iid: pipeline.iid, includeCommitInfo: true }
      )

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}get_pipelines.query.graphql.json" do
      # An older pipeline so `first: 2` leaves a second page (exercises pagination)
      create(:ci_pipeline, :with_job, project: project)

      # One pipeline triggers another so the two returned rows exercise both mini-graph links:
      # the parent gets a downstream, the child an upstream.
      parent_pipeline = create(:ci_pipeline, :with_job, project: project)
      parent_bridge = create(:ci_bridge, pipeline: parent_pipeline)
      child_pipeline = create(:ci_pipeline, :with_job, project: project)
      create(:ci_sources_pipeline, pipeline: child_pipeline, source_job: parent_bridge)

      post_graphql(
        queries[:pipelines],
        current_user: user,
        variables: { fullPath: project.full_path, first: 2 }
      )

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}get_single_pipeline.query.graphql.json" do
      pipeline = create(:ci_pipeline, :with_test_reports, project: project, sha: commit.id, user: user)
      build_stage = create(:ci_stage, name: 'build', pipeline: pipeline, project: project)
      deploy_stage = create(:ci_stage, name: 'deploy', pipeline: pipeline, project: project)
      create(:ci_build, pipeline: pipeline, ci_stage: build_stage)
      create(:ci_build, pipeline: pipeline, ci_stage: pipeline.stage('test'))
      create(:ci_build, status: :failed, pipeline: pipeline, ci_stage: deploy_stage)

      post_graphql(
        queries[:single_pipeline],
        current_user: user,
        variables: { fullPath: project.full_path, id: pipeline.to_global_id.to_s }
      )

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}get_commit_pipelines.query.graphql.json" do
      # The latest pipeline for the commit: full commit + author, stages with builds, and a
      # downstream pipeline created in the same project so its nested nodes are readable.
      pipeline = create(:ci_pipeline, :with_test_reports, project: project, sha: commit.id, user: user)
      build_stage = create(:ci_stage, name: 'build', pipeline: pipeline, project: project)
      create(:ci_build, pipeline: pipeline, ci_stage: build_stage)
      create(:ci_build, pipeline: pipeline, ci_stage: pipeline.stage('test'))
      create(:ci_sources_pipeline,
        pipeline: create(:ci_pipeline, :with_job, project: project),
        source_job: create(:ci_bridge, pipeline: pipeline))

      # An older pipeline for the same commit so the connection returns two rows.
      create(:ci_pipeline, :with_job, project: project, sha: commit.id, user: user)

      post_graphql(
        queries[:commit_pipelines],
        current_user: user,
        variables: { fullPath: project.full_path, sha: commit.sha, first: 20 }
      )

      expect_graphql_errors_to_be_empty
    end
  end
end
