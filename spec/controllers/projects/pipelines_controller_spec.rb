# frozen_string_literal: true

require 'spec_helper'

describe Projects::PipelinesController do
  include ApiHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:feature) { ProjectFeature::ENABLED }

  before do
    stub_not_protect_default_branch
    project.add_developer(user)
    project.project_feature.update(builds_access_level: feature)

    sign_in(user)
  end

  describe 'GET index.json' do
    before do
      create_all_pipeline_types
    end

    context 'when using persisted stages', :request_store do
      render_views

      before do
        stub_feature_flags(ci_pipeline_persisted_stages: true)
      end

      it 'returns serialized pipelines', :request_store do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

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
        get_pipelines_index_json

        control_count = ActiveRecord::QueryRecorder.new do
          get_pipelines_index_json
        end.count

        create_all_pipeline_types

        # There appears to be one extra query for Pipelines#has_warnings? for some reason
        expect { get_pipelines_index_json }.not_to exceed_query_limit(control_count + 1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['pipelines'].count).to eq 10
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

        # ListCommitsByOid, RepositoryExists, HasLocalBranches
        expect { get_pipelines_index_json }
          .to change { Gitlab::GitalyClient.get_request_count }.by(3)
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

    def create_all_pipeline_types
      %w(pending running success failed canceled).each_with_index do |status, index|
        create_pipeline(status, project.commit("HEAD~#{index}"))
      end
    end

    def create_pipeline(status, sha)
      user = create(:user)
      pipeline = create(:ci_empty_pipeline, status: status,
                                            project: project,
                                            sha: sha,
                                            user: user)

      create_build(pipeline, 'build', 1, 'build', user)
      create_build(pipeline, 'test', 2, 'test', user)
      create_build(pipeline, 'deploy', 3, 'deploy', user)
    end

    def create_build(pipeline, stage, stage_idx, name, user = nil)
      status = %w[created running pending success failed canceled].sample
      create(:ci_build, pipeline: pipeline, stage: stage, stage_idx: stage_idx, name: name, status: status, user: user)
    end
  end

  describe 'GET show.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

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

    context 'with triggered pipelines' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:source_project) { create(:project, :repository) }
      let_it_be(:target_project) { create(:project, :repository) }
      let_it_be(:root_pipeline) { create_pipeline(project) }
      let_it_be(:source_pipeline) { create_pipeline(source_project) }
      let_it_be(:source_of_source_pipeline) { create_pipeline(source_project) }
      let_it_be(:target_pipeline) { create_pipeline(target_project) }
      let_it_be(:target_of_target_pipeline) { create_pipeline(target_project) }

      before do
        create_link(source_of_source_pipeline, source_pipeline)
        create_link(source_pipeline, root_pipeline)
        create_link(root_pipeline, target_pipeline)
        create_link(target_pipeline, target_of_target_pipeline)
      end

      shared_examples 'not expanded' do
        let(:expected_stages) { be_nil }

        it 'does return base details' do
          get_pipeline_json(root_pipeline)

          expect(json_response['triggered_by']).to include('id' => source_pipeline.id)
          expect(json_response['triggered']).to contain_exactly(
            include('id' => target_pipeline.id))
        end

        it 'does not expand triggered_by pipeline' do
          get_pipeline_json(root_pipeline)

          triggered_by = json_response['triggered_by']
          expect(triggered_by['triggered_by']).to be_nil
          expect(triggered_by['triggered']).to be_nil
          expect(triggered_by['details']['stages']).to expected_stages
        end

        it 'does not expand triggered pipelines' do
          get_pipeline_json(root_pipeline)

          first_triggered = json_response['triggered'].first
          expect(first_triggered['triggered_by']).to be_nil
          expect(first_triggered['triggered']).to be_nil
          expect(first_triggered['details']['stages']).to expected_stages
        end
      end

      shared_examples 'expanded' do
        it 'does return base details' do
          get_pipeline_json(root_pipeline)

          expect(json_response['triggered_by']).to include('id' => source_pipeline.id)
          expect(json_response['triggered']).to contain_exactly(
            include('id' => target_pipeline.id))
        end

        it 'does expand triggered_by pipeline' do
          get_pipeline_json(root_pipeline)

          triggered_by = json_response['triggered_by']
          expect(triggered_by['triggered_by']).to include(
            'id' => source_of_source_pipeline.id)
          expect(triggered_by['details']['stages']).not_to be_nil
        end

        it 'does not recursively expand triggered_by' do
          get_pipeline_json(root_pipeline)

          triggered_by = json_response['triggered_by']
          expect(triggered_by['triggered']).to be_nil
        end

        it 'does expand triggered pipelines' do
          get_pipeline_json(root_pipeline)

          first_triggered = json_response['triggered'].first
          expect(first_triggered['triggered']).to contain_exactly(
            include('id' => target_of_target_pipeline.id))
          expect(first_triggered['details']['stages']).not_to be_nil
        end

        it 'does not recursively expand triggered' do
          get_pipeline_json(root_pipeline)

          first_triggered = json_response['triggered'].first
          expect(first_triggered['triggered_by']).to be_nil
        end
      end

      context 'when it does have permission to read other projects' do
        before do
          source_project.add_developer(user)
          target_project.add_developer(user)
        end

        context 'when not-expanding any pipelines' do
          let(:expanded) { nil }

          it_behaves_like 'not expanded'
        end

        context 'when expanding non-existing pipeline' do
          let(:expanded) { [-1] }

          it_behaves_like 'not expanded'
        end

        context 'when expanding pipeline that is not directly expandable' do
          let(:expanded) { [source_of_source_pipeline.id, target_of_target_pipeline.id] }

          it_behaves_like 'not expanded'
        end

        context 'when expanding self' do
          let(:expanded) { [root_pipeline.id] }

          context 'it does not recursively expand pipelines' do
            it_behaves_like 'not expanded'
          end
        end

        context 'when expanding source and target pipeline' do
          let(:expanded) { [source_pipeline.id, target_pipeline.id] }

          it_behaves_like 'expanded'

          context 'when expand depth is limited to 1' do
            before do
              stub_const('TriggeredPipelineEntity::MAX_EXPAND_DEPTH', 1)
            end

            it_behaves_like 'not expanded' do
              # We expect that triggered/triggered_by is not expanded,
              # but we still return details.stages for that pipeline
              let(:expected_stages) { be_a(Array) }
            end
          end
        end

        context 'when expanding all' do
          let(:expanded) do
            [
              source_of_source_pipeline.id,
              source_pipeline.id,
              root_pipeline.id,
              target_pipeline.id,
              target_of_target_pipeline.id
            ]
          end

          it_behaves_like 'expanded'
        end
      end

      context 'when does not have permission to read other projects' do
        let(:expanded) { [source_pipeline.id, target_pipeline.id] }

        it_behaves_like 'not expanded'
      end

      def create_pipeline(project)
        create(:ci_empty_pipeline, project: project).tap do |pipeline|
          create(:ci_build, pipeline: pipeline, stage: 'test', name: 'rspec')
        end
      end

      def create_link(source_pipeline, pipeline)
        source_pipeline.sourced_pipelines.create!(
          source_job: source_pipeline.builds.all.sample,
          source_project: source_pipeline.project,
          project: pipeline.project,
          pipeline: pipeline
        )
      end

      def get_pipeline_json(pipeline)
        params = {
          namespace_id: pipeline.project.namespace,
          project_id: pipeline.project,
          id: pipeline,
          expanded: expanded
        }

        get :show, params: params.compact, format: :json
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

    it 'cancels a pipeline without returning any content', :sidekiq_might_not_need_inline do
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

  describe 'GET test_report.json' do
    subject(:get_test_report_json) do
      post :test_report, params: {
        namespace_id: project.namespace,
        project_id: project,
        id: pipeline.id
      },
      format: :json
    end

    context 'when feature is enabled' do
      before do
        stub_feature_flags(junit_pipeline_view: true)
      end

      context 'when pipeline does not have a test report' do
        let(:pipeline) { create(:ci_pipeline, project: project) }

        it 'renders an empty test report' do
          get_test_report_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['total_count']).to eq(0)
        end
      end

      context 'when pipeline has a test report' do
        let(:pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }

        it 'renders the test report' do
          get_test_report_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['total_count']).to eq(4)
        end
      end

      context 'when pipeline has corrupt test reports' do
        let(:pipeline) { create(:ci_pipeline, project: project) }

        before do
          job = create(:ci_build, pipeline: pipeline)
          create(:ci_job_artifact, :junit_with_corrupted_data, job: job, project: project)
        end

        it 'renders the test reports' do
          get_test_report_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['status']).to eq('error_parsing_report')
        end
      end
    end

    context 'when feature is disabled' do
      let(:pipeline) { create(:ci_empty_pipeline, project: project) }

      before do
        stub_feature_flags(junit_pipeline_view: false)
      end

      it 'renders empty response' do
        get_test_report_json

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_empty
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

  describe 'DELETE #destroy' do
    let!(:project) { create(:project, :private, :repository) }
    let!(:pipeline) { create(:ci_pipeline, :failed, project: project) }
    let!(:build) { create(:ci_build, :failed, pipeline: pipeline) }

    context 'when user has ability to delete pipeline' do
      before do
        sign_in(project.owner)
      end

      it 'deletes pipeline and redirects' do
        delete_pipeline

        expect(response).to have_gitlab_http_status(303)

        expect(Ci::Build.exists?(build.id)).to be_falsy
        expect(Ci::Pipeline.exists?(pipeline.id)).to be_falsy
      end

      context 'and builds are disabled' do
        let(:feature) { ProjectFeature::DISABLED }

        it 'fails to delete pipeline' do
          delete_pipeline

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when user has no privileges' do
      it 'fails to delete pipeline' do
        delete_pipeline

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def delete_pipeline
      delete :destroy, params: {
                         namespace_id: project.namespace,
                         project_id: project,
                         id: pipeline.id
                       }
    end
  end
end
