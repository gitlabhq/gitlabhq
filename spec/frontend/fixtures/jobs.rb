# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::JobsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'builds-project') }
  let(:user) { project.owner }
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
    clean_frontend_fixtures('jobs/')
  end

  before do
    sign_in(user)
  end

  after do
    remove_repository(project)
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
