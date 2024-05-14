# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelinesController, '(JavaScript fixtures)', type: :controller do
  include ApiHelpers
  include GraphqlHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let_it_be(:project) { create(:project, :repository, namespace: namespace, path: 'pipelines-project') }

  let_it_be(:commit_without_author) { RepoHelpers.another_sample_commit }
  let!(:pipeline_without_author) { create(:ci_pipeline, project: project, sha: commit_without_author.id) }
  let!(:build_pipeline_without_author) { create(:ci_build, pipeline: pipeline_without_author, stage: 'test') }

  let_it_be(:pipeline_without_commit) { create(:ci_pipeline, status: :success, project: project, sha: '0000') }

  let!(:build_pipeline_without_commit) { create(:ci_build, pipeline: pipeline_without_commit, stage: 'test') }

  let(:commit) { create(:commit, project: project) }
  let(:user) { create(:user, developer_of: project, email: commit.author_email) }
  let!(:pipeline) { create(:ci_pipeline, :with_test_reports, project: project, sha: commit.id, user: user) }
  let!(:build_success) { create(:ci_build, pipeline: pipeline, stage: 'build') }
  let!(:build_test) { create(:ci_build, pipeline: pipeline, stage: 'test') }
  let!(:build_deploy_failed) { create(:ci_build, status: :failed, pipeline: pipeline, stage: 'deploy') }

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
    get_pipeline_actions_query = 'get_pipeline_actions.query.graphql'

    let!(:pipeline_with_manual_actions) { create(:ci_pipeline, project: project, user: user) }
    let!(:build_scheduled) { create(:ci_build, :scheduled, pipeline: pipeline_with_manual_actions, stage: 'test') }
    let!(:build_manual) { create(:ci_build, :manual, pipeline: pipeline_with_manual_actions, stage: 'build') }
    let!(:build_manual_cannot_play) do
      create(:ci_build, :manual, :skipped, pipeline: pipeline_with_manual_actions, stage: 'build')
    end

    let_it_be(:query) do
      get_graphql_query_as_string("ci/pipelines_page/graphql/queries/#{get_pipeline_actions_query}")
    end

    it "#{fixtures_path}#{get_pipeline_actions_query}.json" do
      post_graphql(query, current_user: user,
        variables: { fullPath: project.full_path, iid: pipeline_with_manual_actions.iid })

      expect_graphql_errors_to_be_empty
    end
  end
end
