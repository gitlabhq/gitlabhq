# frozen_string_literal: true

require 'spec_helper'

describe Projects::PipelinesController do
  include ApiHelpers

  set(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:feature) { ProjectFeature::ENABLED }

  before do
    stub_not_protect_default_branch
    project.add_developer(user)
    project.project_feature.update(builds_access_level: feature)

    sign_in(user)
  end

  describe 'GET index.json' do
    before do
      %w(pending running success failed canceled).each_with_index do |status, index|
        create_pipeline(status, project.commit("HEAD~#{index}"))
      end
    end

    context 'when using persisted stages', :request_store do
      before do
        stub_feature_flags(ci_pipeline_persisted_stages: true)
      end

      it 'returns serialized pipelines', :request_store do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

        queries = ActiveRecord::QueryRecorder.new do
          get_pipelines_index_json
        end

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('pipeline')

        expect(json_response).to include('pipelines')
        expect(json_response['pipelines'].count).to eq 5
        expect(json_response['count']['all']).to eq '5'
        expect(json_response['count']['running']).to eq '1'
        expect(json_response['count']['pending']).to eq '1'
        expect(json_response['count']['finished']).to eq '3'

        json_response.dig('pipelines', 0, 'details', 'stages').tap do |stages|
          expect(stages.count).to eq 3
        end

        expect(queries.count).to be
      end
    end

    context 'when using legacy stages', :request_store do
      before do
        stub_feature_flags(ci_pipeline_persisted_stages: false)
      end

      it 'returns JSON with serialized pipelines' do
        get_pipelines_index_json

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('pipeline')

        expect(json_response).to include('pipelines')
        expect(json_response['pipelines'].count).to eq 5
        expect(json_response['count']['all']).to eq '5'
        expect(json_response['count']['running']).to eq '1'
        expect(json_response['count']['pending']).to eq '1'
        expect(json_response['count']['finished']).to eq '3'

        json_response.dig('pipelines', 0, 'details', 'stages').tap do |stages|
          expect(stages.count).to eq 3
        end
      end

      it 'does not execute N+1 queries' do
        queries = ActiveRecord::QueryRecorder.new do
          get_pipelines_index_json
        end

        expect(queries.count).to be <= 36
      end
    end

    it 'does not include coverage data for the pipelines' do
      get_pipelines_index_json

      expect(json_response['pipelines'][0]).not_to include('coverage')
    end

    context 'when performing gitaly calls', :request_store do
      it 'limits the Gitaly requests' do
        # Isolate from test preparation (Repository#exists? is also cached in RequestStore)
        RequestStore.end!
        RequestStore.clear!
        RequestStore.begin!

        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

        expect { get_pipelines_index_json }
          .to change { Gitlab::GitalyClient.get_request_count }.by(2)
      end
    end

    context 'when the project is private' do
      let(:project) { create(:project, :private, :repository) }

      it 'returns `not_found` when the user does not have access' do
        sign_in(create(:user))

        get_pipelines_index_json

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns the pipelines when the user has access' do
        get_pipelines_index_json

        expect(json_response['pipelines'].size).to eq(5)
      end
    end

    def get_pipelines_index_json
      get :index, params: {
                    namespace_id: project.namespace,
                    project_id: project
                  },
                  format: :json
    end

    def create_pipeline(status, sha)
      pipeline = create(:ci_empty_pipeline, status: status,
                                            project: project,
                                            sha: sha)

      create_build(pipeline, 'build', 1, 'build')
      create_build(pipeline, 'test', 2, 'test')
      create_build(pipeline, 'deploy', 3, 'deploy')
    end

    def create_build(pipeline, stage, stage_idx, name)
      status = %w[created running pending success failed canceled].sample
      create(:ci_build, pipeline: pipeline, stage: stage, stage_idx: stage_idx, name: name, status: status)
    end
  end

  describe 'GET show.json' do
    let(:pipeline) { create(:ci_pipeline_with_one_job, project: project) }

    it 'returns the pipeline' do
      get_pipeline_json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).not_to be_an(Array)
      expect(json_response['id']).to be(pipeline.id)
      expect(json_response['details']).to have_key 'stages'
    end

    context 'when the pipeline has multiple stages and groups', :request_store do
      let(:project) { create(:project, :repository) }

      let(:pipeline) do
        create(:ci_empty_pipeline, project: project,
                                   user: user,
                                   sha: project.commit.id)
      end

      before do
        create_build('build', 0, 'build')
        create_build('test', 1, 'rspec 0')
        create_build('deploy', 2, 'production')
        create_build('post deploy', 3, 'pages 0')
      end

      it 'does not perform N + 1 queries' do
        # Set up all required variables
        get_pipeline_json

        control_count = ActiveRecord::QueryRecorder.new { get_pipeline_json }.count

        first_build = pipeline.builds.first
        first_build.tag_list << [:hello, :world]
        create(:deployment, deployable: first_build)

        second_build = pipeline.builds.second
        second_build.tag_list << [:docker, :ruby]
        create(:deployment, deployable: second_build)

        new_count = ActiveRecord::QueryRecorder.new { get_pipeline_json }.count

        expect(new_count).to be_within(1).of(control_count)
      end
    end

    context 'when builds are disabled' do
      let(:feature) { ProjectFeature::DISABLED }

      it 'users can not see internal pipelines' do
        get_pipeline_json

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when pipeline is external' do
        let(:pipeline) { create(:ci_pipeline, source: :external, project: project) }

        it 'users can see the external pipeline' do
          get_pipeline_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to be(pipeline.id)
        end
      end
    end

    def get_pipeline_json
      get :show, params: { namespace_id: project.namespace, project_id: project, id: pipeline }, format: :json
    end

    def create_build(stage, stage_idx, name)
      create(:ci_build, pipeline: pipeline, stage: stage, stage_idx: stage_idx, name: name)
    end
  end

  describe 'GET stages.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    context 'when accessing existing stage' do
      before do
        create(:ci_build, :retried, :failed, pipeline: pipeline, stage: 'build')
        create(:ci_build, pipeline: pipeline, stage: 'build')
      end

      context 'without retried' do
        before do
          get_stage('build')
        end

        it 'returns pipeline jobs without the retried builds' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('pipeline_stage')
          expect(json_response['latest_statuses'].length).to eq 1
          expect(json_response).not_to have_key('retried')
        end
      end

      context 'with retried' do
        before do
          get_stage('build', retried: true)
        end

        it 'returns pipelines jobs with the retried builds' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('pipeline_stage')
          expect(json_response['latest_statuses'].length).to eq 1
          expect(json_response['retried'].length).to eq 1
        end
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

    def get_stage(name, params = {})
      get :stage, params: {
**params.merge(
  namespace_id: project.namespace,
  project_id: project,
  id: pipeline.id,
  stage: name,
  format: :json)
}
    end
  end

  describe 'GET stages_ajax.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    context 'when accessing existing stage' do
      before do
        create(:ci_build, pipeline: pipeline, stage: 'build')

        get_stage_ajax('build')
      end

      it 'returns html source for stage dropdown' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('projects/pipelines/_stage')
        expect(json_response).to include('html')
      end
    end

    context 'when accessing unknown stage' do
      before do
        get_stage_ajax('test')
      end

      it 'responds with not found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_stage_ajax(name)
      get :stage_ajax, params: {
                         namespace_id: project.namespace,
                         project_id: project,
                         id: pipeline.id,
                         stage: name
                       },
                       format: :json
    end
  end

  describe 'GET status.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:status) { pipeline.detailed_status(double('user')) }

    before do
      get :status, params: {
                     namespace_id: project.namespace,
                     project_id: project,
                     id: pipeline.id
                   },
                   format: :json
    end

    it 'return a detailed pipeline status in json' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['text']).to eq status.text
      expect(json_response['label']).to eq status.label
      expect(json_response['icon']).to eq status.icon
      expect(json_response['favicon']).to match_asset_path("/assets/ci_favicons/#{status.favicon}.png")
    end
  end

  describe 'POST retry.json' do
    let!(:pipeline) { create(:ci_pipeline, :failed, project: project) }
    let!(:build) { create(:ci_build, :failed, pipeline: pipeline) }

    before do
      post :retry, params: {
                     namespace_id: project.namespace,
                     project_id: project,
                     id: pipeline.id
                   },
                   format: :json
    end

    it 'retries a pipeline without returning any content' do
      expect(response).to have_gitlab_http_status(:no_content)
      expect(build.reload).to be_retried
    end

    context 'when builds are disabled' do
      let(:feature) { ProjectFeature::DISABLED }

      it 'fails to retry pipeline' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST cancel.json' do
    let!(:pipeline) { create(:ci_pipeline, project: project) }
    let!(:build) { create(:ci_build, :running, pipeline: pipeline) }

    before do
      post :cancel, params: {
                      namespace_id: project.namespace,
                      project_id: project,
                      id: pipeline.id
                    },
                    format: :json
    end

    it 'cancels a pipeline without returning any content' do
      expect(response).to have_gitlab_http_status(:no_content)
      expect(pipeline.reload).to be_canceled
    end

    context 'when builds are disabled' do
      let(:feature) { ProjectFeature::DISABLED }

      it 'fails to retry pipeline' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET latest' do
    let(:branch_main) { project.repository.branches[0] }
    let(:branch_secondary) { project.repository.branches[1] }

    let!(:pipeline_master) do
      create(:ci_pipeline,
             ref: branch_main.name,
             sha: branch_main.target,
             project: project)
    end

    let!(:pipeline_secondary) do
      create(:ci_pipeline,
             ref: branch_secondary.name,
             sha: branch_secondary.target,
             project: project)
    end

    before do
      project.change_head(branch_main.name)
      project.reload_default_branch
    end

    context 'no ref provided' do
      it 'shows latest pipeline for the default project branch' do
        get :show, params: { namespace_id: project.namespace, project_id: project, latest: true, ref: nil }

        expect(response).to have_gitlab_http_status(200)
        expect(assigns(:pipeline)).to have_attributes(id: pipeline_master.id)
      end
    end

    context 'ref provided' do
      before do
        create(:ci_pipeline, ref: 'master', project: project)
      end

      it 'shows the latest pipeline for the provided ref' do
        get :show, params: { namespace_id: project.namespace, project_id: project, latest: true, ref: branch_secondary.name }

        expect(response).to have_gitlab_http_status(200)
        expect(assigns(:pipeline)).to have_attributes(id: pipeline_secondary.id)
      end

      context 'newer pipeline exists for older sha' do
        before do
          create(:ci_pipeline, ref: branch_secondary.name, sha: project.commit(branch_secondary.name).parent, project: project)
        end

        it 'shows the provided ref with the last sha/pipeline combo' do
          get :show, params: { namespace_id: project.namespace, project_id: project, latest: true, ref: branch_secondary.name }

          expect(response).to have_gitlab_http_status(200)
          expect(assigns(:pipeline)).to have_attributes(id: pipeline_secondary.id)
        end
      end
    end

    it 'renders a 404 if no pipeline is found for the ref' do
      get :show, params: { namespace_id: project.namespace, project_id: project, ref: 'no-branch' }

      expect(response).to have_gitlab_http_status(404)
    end
  end
end
