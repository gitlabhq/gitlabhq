require 'spec_helper'

describe Projects::PipelinesController do
  include ApiHelpers

  set(:user) { create(:user) }
  set(:project) { create(:project, :public, :repository) }
  let(:feature) { ProjectFeature::DISABLED }

  before do
    stub_not_protect_default_branch
    project.add_developer(user)
    project.project_feature.update(builds_access_level: feature)

    sign_in(user)
  end

  describe 'GET index.json' do
    before do
      %w(pending running created success).each_with_index do |status, index|
        sha = project.commit("HEAD~#{index}")
        create(:ci_empty_pipeline, status: status, project: project, sha: sha)
      end
    end

    subject do
      get :index, namespace_id: project.namespace, project_id: project, format: :json
    end

    it 'returns JSON with serialized pipelines' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('pipeline')

      expect(json_response).to include('pipelines')
      expect(json_response['pipelines'].count).to eq 4
      expect(json_response['count']['all']).to eq 4
      expect(json_response['count']['running']).to eq 1
      expect(json_response['count']['pending']).to eq 1
      expect(json_response['count']['finished']).to eq 1
    end

    context 'when performing gitaly calls', :request_store do
      it 'limits the Gitaly requests' do
        expect { subject }.to change { Gitlab::GitalyClient.get_request_count }.by(3)
      end
    end
  end

  describe 'GET show JSON' do
    let(:pipeline) { create(:ci_pipeline_with_one_job, project: project) }

    it 'returns the pipeline' do
      get_pipeline_json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).not_to be_an(Array)
      expect(json_response['id']).to be(pipeline.id)
      expect(json_response['details']).to have_key 'stages'
    end

    context 'when the pipeline has multiple stages and groups', :request_store do
      before do
        create_build('build', 0, 'build')
        create_build('test', 1, 'rspec 0')
        create_build('deploy', 2, 'production')
        create_build('post deploy', 3, 'pages 0')
      end

      let(:project) { create(:project, :repository) }
      let(:pipeline) do
        create(:ci_empty_pipeline, project: project, user: user, sha: project.commit.id)
      end

      it 'does not perform N + 1 queries' do
        control_count = ActiveRecord::QueryRecorder.new { get_pipeline_json }.count

        create_build('test', 1, 'rspec 1')
        create_build('test', 1, 'spinach 0')
        create_build('test', 1, 'spinach 1')
        create_build('test', 1, 'audit')
        create_build('post deploy', 3, 'pages 1')
        create_build('post deploy', 3, 'pages 2')

        new_count = ActiveRecord::QueryRecorder.new { get_pipeline_json }.count
        expect(new_count).to be_within(12).of(control_count)
      end
    end

    def get_pipeline_json
      get :show, namespace_id: project.namespace, project_id: project, id: pipeline, format: :json
    end

    def create_build(stage, stage_idx, name)
      create(:ci_build, pipeline: pipeline, stage: stage, stage_idx: stage_idx, name: name)
    end
  end

  describe 'GET stages.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    context 'when accessing existing stage' do
      before do
        create(:ci_build, pipeline: pipeline, stage: 'build')

        get_stage('build')
      end

      it 'returns html source for stage dropdown' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('projects/pipelines/_stage')
        expect(json_response).to include('html')
      end
    end

    context 'when accessing unknown stage' do
      before do
        get_stage('test')
      end

      it 'responds with not found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_stage(name)
      get :stage, namespace_id: project.namespace,
                  project_id: project,
                  id: pipeline.id,
                  stage: name,
                  format: :json
    end
  end

  describe 'GET status.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:status) { pipeline.detailed_status(double('user')) }

    before do
      get :status, namespace_id: project.namespace,
                   project_id: project,
                   id: pipeline.id,
                   format: :json
    end

    it 'return a detailed pipeline status in json' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['text']).to eq status.text
      expect(json_response['label']).to eq status.label
      expect(json_response['icon']).to eq status.icon
      expect(json_response['favicon']).to match_asset_path("/assets/ci_favicons/#{status.favicon}.ico")
    end
  end

  describe 'POST retry.json' do
    let!(:pipeline) { create(:ci_pipeline, :failed, project: project) }
    let!(:build) { create(:ci_build, :failed, pipeline: pipeline) }

    before do
      post :retry, namespace_id: project.namespace,
                   project_id: project,
                   id: pipeline.id,
                   format: :json
    end

    context 'when builds are enabled' do
      let(:feature) { ProjectFeature::ENABLED }

      it 'retries a pipeline without returning any content' do
        expect(response).to have_gitlab_http_status(:no_content)
        expect(build.reload).to be_retried
      end
    end

    context 'when builds are disabled' do
      it 'fails to retry pipeline' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST cancel.json' do
    let!(:pipeline) { create(:ci_pipeline, project: project) }
    let!(:build) { create(:ci_build, :running, pipeline: pipeline) }

    before do
      post :cancel, namespace_id: project.namespace,
                    project_id: project,
                    id: pipeline.id,
                    format: :json
    end

    context 'when builds are enabled' do
      let(:feature) { ProjectFeature::ENABLED }

      it 'cancels a pipeline without returning any content' do
        expect(response).to have_gitlab_http_status(:no_content)
        expect(pipeline.reload).to be_canceled
      end
    end

    context 'when builds are disabled' do
      it 'fails to retry pipeline' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
