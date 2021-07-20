# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelinesController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let_it_be(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let_it_be(:project) { create(:project, :repository, namespace: namespace, path: 'pipelines-project') }

  let_it_be(:commit_without_author) { RepoHelpers.another_sample_commit }
  let!(:pipeline_without_author) { create(:ci_pipeline, project: project, sha: commit_without_author.id) }
  let!(:build_pipeline_without_author) { create(:ci_build, pipeline: pipeline_without_author, stage: 'test') }

  let_it_be(:pipeline_without_commit) { create(:ci_pipeline, status: :success, project: project, sha: '0000') }

  let!(:build_pipeline_without_commit) { create(:ci_build, pipeline: pipeline_without_commit, stage: 'test') }

  let(:commit) { create(:commit, project: project) }
  let(:user) { create(:user, developer_projects: [project], email: commit.author_email) }
  let!(:pipeline) { create(:ci_pipeline, :with_test_reports, project: project, sha: commit.id, user: user) }
  let!(:build_success) { create(:ci_build, pipeline: pipeline, stage: 'build') }
  let!(:build_test) { create(:ci_build, pipeline: pipeline, stage: 'test') }
  let!(:build_deploy_failed) { create(:ci_build, status: :failed, pipeline: pipeline, stage: 'deploy') }

  before(:all) do
    clean_frontend_fixtures('pipelines/')
  end

  before do
    sign_in(user)
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
end
