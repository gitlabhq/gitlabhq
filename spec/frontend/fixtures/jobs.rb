require 'spec_helper'

describe Projects::JobsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'builds-project') }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.id) }
  let!(:build_with_artifacts) { create(:ci_build, :success, :artifacts, :trace_artifact, pipeline: pipeline, stage: 'test', artifacts_expire_at: Time.now + 18.months) }
  let!(:failed_build) { create(:ci_build, :failed, pipeline: pipeline, stage: 'build') }
  let!(:pending_build) { create(:ci_build, :pending, pipeline: pipeline, stage: 'deploy') }
  let!(:delayed_job) do
    create(:ci_build, :scheduled,
           pipeline: pipeline,
           name: 'delayed job',
           stage: 'test')
  end

  render_views

  before(:all) do
    clean_frontend_fixtures('builds/')
    clean_frontend_fixtures('jobs/')
  end

  before do
    sign_in(admin)
  end

  after do
    remove_repository(project)
  end

  it 'builds/build-with-artifacts.html' do
    get :show, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: build_with_artifacts.to_param
    }

    expect(response).to be_successful
  end

  it 'jobs/delayed.json' do
    get :show, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: delayed_job.to_param
    }, format: :json

    expect(response).to be_successful
  end
end
