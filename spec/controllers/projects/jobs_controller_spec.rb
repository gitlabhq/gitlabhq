# frozen_string_literal: true
require 'spec_helper'

describe Projects::JobsController, :clean_gitlab_redis_shared_state do
  include ApiHelpers
  include HttpIOHelpers

  let(:project) { create(:project, :public) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:user) { create(:user) }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
    stub_not_protect_default_branch
  end

  describe 'GET index' do
    context 'when scope is pending' do
      before do
        create(:ci_build, :pending, pipeline: pipeline)

        get_index(scope: 'pending')
      end

      it 'has only pending builds' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:builds).first.status).to eq('pending')
      end
    end

    context 'when scope is running' do
      before do
        create(:ci_build, :running, pipeline: pipeline)

        get_index(scope: 'running')
      end

      it 'has only running jobs' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:builds).first.status).to eq('running')
      end
    end

    context 'when scope is finished' do
      before do
        create(:ci_build, :success, pipeline: pipeline)

        get_index(scope: 'finished')
      end

      it 'has only finished jobs' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:builds).first.status).to eq('success')
      end
    end

    context 'when page is specified' do
      let(:last_page) { project.builds.page.total_pages }

      context 'when page number is eligible' do
        before do
          create_list(:ci_build, 2, pipeline: pipeline)

          get_index(page: last_page.to_param)
        end

        it 'redirects to the page' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:builds).current_page).to eq(last_page)
        end
      end
    end

    context 'number of queries' do
      render_views

      before do
        Ci::Build::AVAILABLE_STATUSES.each do |status|
          create_job(status, status)
        end

        allow(Appearance).to receive(:current_without_cache)
          .and_return(nil)
      end

      it 'verifies number of queries', :request_store do
        expect { get_index }.not_to be_n_plus_1_query.with_threshold(3)
      end

      def create_job(name, status)
        user = create(:user)
        pipeline = create(:ci_pipeline, project: project, user: user)
        create(:ci_build, :tags, :triggered, :artifacts,
               pipeline: pipeline, name: name, status: status,
               user: user)
      end
    end

    def get_index(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      get :index, params: params.merge(extra_params)
    end
  end

  describe 'GET show', :request_store do
    let!(:job) { create(:ci_build, :failed, pipeline: pipeline) }
    let!(:second_job) { create(:ci_build, :failed, pipeline: pipeline) }
    let!(:third_job) { create(:ci_build, :failed) }

    context 'when requesting HTML' do
      context 'when job exists' do
        before do
          get_show(id: job.id)
        end

        it 'has a job' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:build).id).to eq(job.id)
        end

        it 'has the correct build collection' do
          builds = assigns(:builds).map(&:id)

          expect(builds).to include(job.id, second_job.id)
          expect(builds).not_to include(third_job.id)
        end
      end

      context 'when job does not exist' do
        before do
          get_show(id: 1234)
        end

        it 'renders not_found' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when requesting JSON' do
      let(:merge_request) { create(:merge_request, source_project: project) }

      before do
        project.add_developer(user)
        sign_in(user)

        allow_any_instance_of(Ci::Build)
          .to receive(:merge_request)
          .and_return(merge_request)
      end

      it 'does not serialize builds in exposed stages' do
        get_show_json

        json_response.dig('pipeline', 'details', 'stages').tap do |stages|
          expect(stages.flat_map(&:keys))
            .to eq %w[name title status path dropdown_path]
        end
      end

      context 'when job failed' do
        it 'exposes needed information' do
          get_show_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details')
          expect(json_response['raw_path']).to match(%r{jobs/\d+/raw\z})
          expect(json_response['merge_request']['path']).to match(%r{merge_requests/\d+\z})
          expect(json_response['new_issue_path']).to include('/issues/new')
        end
      end

      context 'when job is running' do
        before do
          get_show_json
        end

        context 'job is cancelable' do
          let(:job) { create(:ci_build, :running, pipeline: pipeline) }

          it 'cancel_path is present with correct redirect' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
            expect(json_response['cancel_path']).to include(CGI.escape(json_response['build_path']))
          end
        end

        context 'with web terminal' do
          let(:job) { create(:ci_build, :running, :with_runner_session, pipeline: pipeline) }

          it 'exposes the terminal path' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
            expect(json_response['terminal_path']).to match(%r{/terminal})
          end
        end
      end

      context 'when job has artifacts' do
        before do
          get_show_json
        end

        context 'with not expiry date' do
          let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

          it 'exposes needed information' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
            expect(json_response['artifact']['download_path']).to match(%r{artifacts/download})
            expect(json_response['artifact']['browse_path']).to match(%r{artifacts/browse})
            expect(json_response['artifact']).not_to have_key('expired')
            expect(json_response['artifact']).not_to have_key('expired_at')
          end
        end

        context 'with expiry date' do
          let(:job) { create(:ci_build, :success, :artifacts, :expired, pipeline: pipeline) }

          it 'exposes needed information' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
            expect(json_response['artifact']).not_to have_key('download_path')
            expect(json_response['artifact']).not_to have_key('browse_path')
            expect(json_response['artifact']['expired']).to eq(true)
            expect(json_response['artifact']['expire_at']).not_to be_empty
          end
        end
      end

      context 'when job passed with no trace' do
        let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

        it 'exposes empty state illustrations' do
          get_show_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details')
          expect(json_response['status']['illustration']).to have_key('image')
          expect(json_response['status']['illustration']).to have_key('size')
          expect(json_response['status']['illustration']).to have_key('title')
        end
      end

      context 'with no deployment' do
        let(:job) { create(:ci_build, :success, pipeline: pipeline) }

        it 'does not exposes the deployment information' do
          get_show_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['deployment_status']).to be_nil
        end
      end

      context 'with deployment' do
        let(:merge_request) { create(:merge_request, source_project: project) }
        let(:environment) { create(:environment, project: project, name: 'staging', state: :available) }
        let(:job) { create(:ci_build, :running, environment: environment.name, pipeline: pipeline) }

        before do
          create(:deployment, :success, :on_cluster, environment: environment, project: project)
          project.add_maintainer(user) # Need to be a maintianer to view cluster.path
        end

        it 'exposes the deployment information' do
          get_show_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to match_schema('job/job_details')
          expect(json_response.dig('deployment_status', 'status')).to eq 'creating'
          expect(json_response.dig('deployment_status', 'environment')).not_to be_nil
          expect(json_response.dig('deployment_status', 'environment', 'last_deployment')).not_to be_nil
          expect(json_response.dig('deployment_status', 'environment', 'last_deployment')).not_to include('commit')
          expect(json_response.dig('deployment_status', 'environment', 'last_deployment', 'cluster', 'name')).to eq('test-cluster')
          expect(json_response.dig('deployment_status', 'environment', 'last_deployment', 'cluster', 'path')).to be_present
        end
      end

      context 'when user can edit runner' do
        context 'that belongs to the project' do
          let(:runner) { create(:ci_runner, :project, projects: [project]) }
          let(:job) { create(:ci_build, :success, pipeline: pipeline, runner: runner) }

          before do
            project.add_maintainer(user)
            sign_in(user)
          end

          it 'user can edit runner' do
            get_show_json

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
            expect(json_response['runner']).to have_key('edit_path')
          end
        end

        context 'that belongs to group' do
          let(:group) { create(:group) }
          let(:runner) { create(:ci_runner, :group, groups: [group]) }
          let(:job) { create(:ci_build, :success, pipeline: pipeline, runner: runner) }
          let(:user) { create(:user, :admin) }

          before do
            project.add_maintainer(user)
            sign_in(user)
          end

          it 'user can not edit runner' do
            get_show_json

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
            expect(json_response['runner']).not_to have_key('edit_path')
          end
        end

        context 'that belongs to instance' do
          let(:runner) { create(:ci_runner, :instance) }
          let(:job) { create(:ci_build, :success, pipeline: pipeline, runner: runner) }
          let(:user) { create(:user, :admin) }

          before do
            project.add_maintainer(user)
            sign_in(user)
          end

          it 'user can not edit runner' do
            get_show_json

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
            expect(json_response['runner']).not_to have_key('edit_path')
          end
        end
      end

      context 'when no runners are available' do
        let(:runner) { create(:ci_runner, :instance, active: false) }
        let(:job) { create(:ci_build, :pending, pipeline: pipeline, runner: runner) }

        it 'exposes needed information' do
          get_show_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details')
          expect(json_response['runners']['online']).to be false
          expect(json_response['runners']['available']).to be false
          expect(json_response['stuck']).to be true
        end
      end

      context 'when no runner is online' do
        let(:runner) { create(:ci_runner, :instance) }
        let(:job) { create(:ci_build, :pending, pipeline: pipeline, runner: runner) }

        it 'exposes needed information' do
          get_show_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details')
          expect(json_response['runners']['online']).to be false
          expect(json_response['runners']['available']).to be true
          expect(json_response['stuck']).to be true
        end
      end

      context 'settings_path' do
        before do
          get_show_json
        end

        context 'when user is developer' do
          it 'settings_path is not available' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
            expect(json_response['runners']).not_to have_key('settings_path')
          end
        end

        context 'when user is maintainer' do
          let(:user) { create(:user, :admin) }

          before do
            project.add_maintainer(user)
            sign_in(user)
          end

          it 'settings_path is available' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
            expect(json_response['runners']['settings_path']).to match(/runners/)
          end
        end
      end

      context 'when no trace is available' do
        it 'has_trace is false' do
          get_show_json

          expect(response).to match_response_schema('job/job_details')
          expect(json_response['has_trace']).to be false
        end
      end

      context 'when job has trace' do
        let(:job) { create(:ci_build, :running, :trace_live, pipeline: pipeline) }

        it "has_trace is true" do
          get_show_json

          expect(response).to match_response_schema('job/job_details')
          expect(json_response['has_trace']).to be true
        end
      end

      it 'exposes the stage the job belongs to' do
        get_show_json

        expect(json_response['stage']).to eq('test')
      end
    end

    context 'when requesting triggered job JSON' do
      let!(:merge_request) { create(:merge_request, source_project: project) }
      let(:trigger) { create(:ci_trigger, project: project) }
      let(:trigger_request) { create(:ci_trigger_request, pipeline: pipeline, trigger: trigger) }
      let(:job) { create(:ci_build, pipeline: pipeline, trigger_request: trigger_request) }

      before do
        project.add_developer(user)
        sign_in(user)

        allow_any_instance_of(Ci::Build)
          .to receive(:merge_request)
          .and_return(merge_request)
      end

      context 'with no variables' do
        it 'exposes trigger information' do
          get_show_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details')
          expect(json_response['trigger']['short_token']).to eq 'toke'
          expect(json_response['trigger']['variables'].length).to eq 0
        end
      end

      context 'with variables' do
        before do
          create(:ci_pipeline_variable, pipeline: pipeline, key: :TRIGGER_KEY_1, value: 'TRIGGER_VALUE_1')
        end

        context 'user is a maintainer' do
          before do
            project.add_maintainer(user)

            get_show_json
          end

          it 'returns a job_detail' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
          end

          it 'exposes trigger information and variables' do
            expect(json_response['trigger']['short_token']).to eq 'toke'
            expect(json_response['trigger']['variables'].length).to eq 1
          end

          it 'exposes correct variable properties' do
            first_variable = json_response['trigger']['variables'].first

            expect(first_variable['key']).to eq "TRIGGER_KEY_1"
            expect(first_variable['value']).to eq "TRIGGER_VALUE_1"
            expect(first_variable['public']).to eq false
          end
        end

        context 'user is not a mantainer' do
          before do
            get_show_json
          end

          it 'returns a job_detail' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
          end

          it 'exposes trigger information and variables' do
            expect(json_response['trigger']['short_token']).to eq 'toke'
            expect(json_response['trigger']['variables'].length).to eq 1
          end

          it 'exposes correct variable properties' do
            first_variable = json_response['trigger']['variables'].first

            expect(first_variable['key']).to eq "TRIGGER_KEY_1"
            expect(first_variable['value']).to be_nil
            expect(first_variable['public']).to eq false
          end
        end
      end
    end

    def get_show_json
      expect { get_show(id: job.id, format: :json) }
        .to change { Gitlab::GitalyClient.get_request_count }.by(1) # ListCommitsByOid
    end

    def get_show(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      get :show, params: params.merge(extra_params)
    end
  end

  describe 'GET trace.json' do
    before do
      get_trace
    end

    context 'when job has a trace artifact' do
      let(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

      it 'returns a trace' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('job/build_trace')
        expect(json_response['id']).to eq job.id
        expect(json_response['status']).to eq job.status
        expect(json_response['state']).to be_present
        expect(json_response['append']).not_to be_nil
        expect(json_response['truncated']).not_to be_nil
        expect(json_response['size']).to be_present
        expect(json_response['total']).to be_present
        expect(json_response['lines'].count).to be_positive
      end
    end

    context 'when job has a trace' do
      let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

      it 'returns a trace' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('job/build_trace')
        expect(json_response['id']).to eq job.id
        expect(json_response['status']).to eq job.status
        expect(json_response['lines']).to eq [{ 'content' => [{ 'text' => 'BUILD TRACE' }], 'offset' => 0 }]
      end
    end

    context 'when job has no traces' do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'returns no traces' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('job/build_trace')
        expect(json_response['id']).to eq job.id
        expect(json_response['status']).to eq job.status
        expect(json_response['lines']).to be_nil
      end
    end

    context 'when job has a trace with ANSI sequence and Unicode' do
      let(:job) { create(:ci_build, :unicode_trace_live, pipeline: pipeline) }

      it 'returns a trace with Unicode' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('job/build_trace')
        expect(json_response['id']).to eq job.id
        expect(json_response['status']).to eq job.status
        expect(json_response['lines'].flat_map {|l| l['content'].map { |c| c['text'] } }).to include("ヾ(´༎ຶД༎ຶ`)ﾉ")
      end
    end

    context 'when trace artifact is in ObjectStorage' do
      let(:url) { 'http://object-storage/trace' }
      let(:file_path) { expand_fixture_path('trace/sample_trace') }
      let!(:job) { create(:ci_build, :success, :trace_artifact, pipeline: pipeline) }

      before do
        allow_any_instance_of(JobArtifactUploader).to receive(:file_storage?) { false }
        allow_any_instance_of(JobArtifactUploader).to receive(:url) { url }
        allow_any_instance_of(JobArtifactUploader).to receive(:size) { File.size(file_path) }
      end

      context 'when there are no network issues' do
        before do
          stub_remote_url_206(url, file_path)

          get_trace
        end

        it 'returns a trace' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq job.id
          expect(json_response['status']).to eq job.status
          expect(json_response['lines'].count).to be_positive
        end
      end

      context 'when there is a network issue' do
        before do
          stub_remote_url_500(url)
        end

        it 'returns a trace' do
          expect { get_trace }.to raise_error(Gitlab::HttpIO::FailedToGetChunkError)
        end
      end
    end

    def get_trace
      get :trace,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          id: job.id
        },
        format: :json
    end
  end

  describe 'GET legacy trace.json' do
    before do
      stub_feature_flags(job_log_json: false)
      get_trace
    end

    context 'when job has a trace artifact' do
      let(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

      it 'returns a trace' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq job.id
        expect(json_response['status']).to eq job.status
        expect(json_response['state']).to be_present
        expect(json_response['append']).not_to be_nil
        expect(json_response['truncated']).not_to be_nil
        expect(json_response['size']).to be_present
        expect(json_response['total']).to be_present
        expect(json_response['html']).to eq(job.trace.html)
      end
    end

    context 'when job has a trace' do
      let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

      it 'returns a trace' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq job.id
        expect(json_response['status']).to eq job.status
        expect(json_response['html']).to eq('<span>BUILD TRACE</span>')
      end
    end

    context 'when job has no traces' do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'returns no traces' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq job.id
        expect(json_response['status']).to eq job.status
        expect(json_response['html']).to be_nil
      end
    end

    context 'when job has a trace with ANSI sequence and Unicode' do
      let(:job) { create(:ci_build, :unicode_trace_live, pipeline: pipeline) }

      it 'returns a trace with Unicode' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq job.id
        expect(json_response['status']).to eq job.status
        expect(json_response['html']).to include("ヾ(´༎ຶД༎ຶ`)ﾉ")
      end
    end

    context 'when trace artifact is in ObjectStorage' do
      let(:url) { 'http://object-storage/trace' }
      let(:file_path) { expand_fixture_path('trace/sample_trace') }
      let!(:job) { create(:ci_build, :success, :trace_artifact, pipeline: pipeline) }

      before do
        allow_any_instance_of(JobArtifactUploader).to receive(:file_storage?) { false }
        allow_any_instance_of(JobArtifactUploader).to receive(:url) { url }
        allow_any_instance_of(JobArtifactUploader).to receive(:size) { File.size(file_path) }
      end

      context 'when there are no network issues' do
        before do
          stub_remote_url_206(url, file_path)

          get_trace
        end

        it 'returns a trace' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq job.id
          expect(json_response['status']).to eq job.status
          expect(json_response['html']).to eq(job.trace.html)
        end
      end

      context 'when there is a network issue' do
        before do
          stub_remote_url_500(url)
        end

        it 'returns a trace' do
          expect { get_trace }.to raise_error(Gitlab::HttpIO::FailedToGetChunkError)
        end
      end
    end

    def get_trace
      get :trace,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          id: job.id
        },
        format: :json
    end
  end

  describe 'GET status.json' do
    let(:job) { create(:ci_build, pipeline: pipeline) }
    let(:status) { job.detailed_status(double('user')) }

    before do
      get :status, params: {
                     namespace_id: project.namespace,
                     project_id: project,
                     id: job.id
                   },
                   format: :json
    end

    it 'return a detailed job status in json' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['text']).to eq status.text
      expect(json_response['label']).to eq status.label
      expect(json_response['icon']).to eq status.icon
      expect(json_response['favicon']).to match_asset_path "/assets/ci_favicons/#{status.favicon}.png"
    end
  end

  describe 'POST retry' do
    before do
      project.add_developer(user)
      sign_in(user)

      post_retry
    end

    context 'when job is retryable' do
      let(:job) { create(:ci_build, :retryable, pipeline: pipeline) }

      it 'redirects to the retried job page' do
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_job_path(id: Ci::Build.last.id))
      end
    end

    context 'when job is not retryable' do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'renders unprocessable_entity' do
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    def post_retry
      post :retry, params: {
                     namespace_id: project.namespace,
                     project_id: project,
                     id: job.id
                   }
    end
  end

  describe 'POST play' do
    let(:variable_attributes) { [] }

    before do
      project.add_developer(user)

      create(:protected_branch, :developers_can_merge,
             name: 'master', project: project)

      sign_in(user)

      post_play
    end

    context 'when job is playable' do
      let(:job) { create(:ci_build, :playable, pipeline: pipeline) }

      it 'redirects to the played job page' do
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_job_path(id: job.id))
      end

      it 'transits to pending' do
        expect(job.reload).to be_pending
      end

      context 'when job variables are specified' do
        let(:variable_attributes) { [{ key: 'first', secret_value: 'first' }] }

        it 'assigns the job variables' do
          expect(job.reload.job_variables.map(&:key)).to contain_exactly('first')
        end
      end
    end

    context 'when job is not playable' do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'renders unprocessable_entity' do
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    def post_play
      post :play, params: {
                    namespace_id: project.namespace,
                    project_id: project,
                    id: job.id,
                    job_variables_attributes: variable_attributes
                  }
    end
  end

  describe 'POST cancel' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    context 'when continue url is present' do
      let(:job) { create(:ci_build, :cancelable, pipeline: pipeline) }

      context 'when continue to is a safe url' do
        let(:url) { '/test' }

        before do
          post_cancel(continue: { to: url })
        end

        it 'redirects to the continue url' do
          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(url)
        end

        it 'transits to canceled' do
          expect(job.reload).to be_canceled
        end
      end

      context 'when continue to is not a safe url' do
        let(:url) { 'http://example.com' }

        it 'raises an error' do
          expect { cancel_with_redirect(url) }.to raise_error
        end
      end
    end

    context 'when continue url is not present' do
      before do
        post_cancel
      end

      context 'when job is cancelable' do
        let(:job) { create(:ci_build, :cancelable, pipeline: pipeline) }

        it 'redirects to the builds page' do
          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(builds_namespace_project_pipeline_path(id: pipeline.id))
        end

        it 'transits to canceled' do
          expect(job.reload).to be_canceled
        end
      end

      context 'when job is not cancelable' do
        let(:job) { create(:ci_build, :canceled, pipeline: pipeline) }

        it 'returns unprocessable_entity' do
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end
    end

    def post_cancel(additional_params = {})
      post :cancel, params: { namespace_id: project.namespace,
                              project_id: project,
                              id: job.id }.merge(additional_params)
    end
  end

  describe 'POST unschedule' do
    before do
      project.add_developer(user)

      create(:protected_branch, :developers_can_merge,
             name: 'master', project: project)

      sign_in(user)

      post_unschedule
    end

    context 'when job is scheduled' do
      let(:job) { create(:ci_build, :scheduled, pipeline: pipeline) }

      it 'redirects to the unscheduled job page' do
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_job_path(id: job.id))
      end

      it 'transits to manual' do
        expect(job.reload).to be_manual
      end
    end

    context 'when job is not scheduled' do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'renders unprocessable_entity' do
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    def post_unschedule
      post :unschedule, params: {
                          namespace_id: project.namespace,
                          project_id: project,
                          id: job.id
                        }
    end
  end

  describe 'POST erase' do
    let(:role) { :maintainer }

    before do
      project.add_role(user, role)
      sign_in(user)

      post_erase
    end

    context 'when job is erasable' do
      let(:job) { create(:ci_build, :erasable, :trace_artifact, pipeline: pipeline) }

      it 'redirects to the erased job page' do
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_job_path(id: job.id))
      end

      it 'erases artifacts' do
        expect(job.artifacts_file.present?).to be_falsey
        expect(job.artifacts_metadata.present?).to be_falsey
      end

      it 'erases trace' do
        expect(job.trace.exist?).to be_falsey
      end
    end

    context 'when job is not erasable' do
      let(:job) { create(:ci_build, :erased, pipeline: pipeline) }

      it 'returns unprocessable_entity' do
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when user is developer' do
      let(:role) { :developer }
      let(:job) { create(:ci_build, :erasable, :trace_artifact, pipeline: pipeline, user: triggered_by) }

      context 'when triggered by same user' do
        let(:triggered_by) { user }

        it 'has successful status' do
          expect(response).to have_gitlab_http_status(:found)
        end
      end

      context 'when triggered by different user' do
        let(:triggered_by) { create(:user) }

        it 'does not have successful status' do
          expect(response).not_to have_gitlab_http_status(:found)
        end
      end
    end

    def post_erase
      post :erase, params: {
                     namespace_id: project.namespace,
                     project_id: project,
                     id: job.id
                   }
    end
  end

  describe 'GET raw' do
    subject do
      post :raw, params: {
                   namespace_id: project.namespace,
                   project_id: project,
                   id: job.id
                 }
    end

    context "when job has a trace artifact" do
      let(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

      it "sets #{Gitlab::Workhorse::DETECT_HEADER} header" do
        response = subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers["Content-Type"]).to eq("text/plain; charset=utf-8")
        expect(response.body).to eq(job.job_artifacts_trace.open.read)
        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
      end
    end

    context "when job has a trace file" do
      let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

      it 'sends a trace file' do
        response = subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers["Content-Type"]).to eq("text/plain; charset=utf-8")
        expect(response.headers["Content-Disposition"]).to match(/^inline/)
        expect(response.body).to eq("BUILD TRACE")
      end
    end

    context "when job has a trace in database" do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      before do
        job.update_column(:trace, "Sample trace")
      end

      it 'sends a trace file' do
        response = subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Type']).to eq('text/plain; charset=utf-8')
        expect(response.headers['Content-Disposition']).to match(/^inline/)
        expect(response.body).to eq('Sample trace')
      end

      context 'when trace format is not text/plain' do
        before do
          job.update_column(:trace, '<html></html>')
        end

        it 'sets content disposition to attachment' do
          response = subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Content-Type']).to eq('text/plain; charset=utf-8')
          expect(response.headers['Content-Disposition']).to match(/^attachment/)
        end
      end
    end

    context 'when job does not have a trace file' do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'returns not_found' do
        response = subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq ''
      end
    end

    context 'when the trace artifact is in ObjectStorage' do
      let!(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

      before do
        allow_any_instance_of(JobArtifactUploader).to receive(:file_storage?) { false }
      end

      it 'redirect to the trace file url' do
        expect(subject).to redirect_to(job.job_artifacts_trace.file.url)
      end
    end
  end

  describe 'GET #terminal' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    context 'when job exists' do
      context 'and it has a terminal' do
        let!(:job) { create(:ci_build, :running, :with_runner_session, pipeline: pipeline) }

        it 'has a job' do
          get_terminal(id: job.id)

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:build).id).to eq(job.id)
        end
      end

      context 'and does not have a terminal' do
        let!(:job) { create(:ci_build, :running, pipeline: pipeline) }

        it 'returns not_found' do
          get_terminal(id: job.id)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when job does not exist' do
      it 'renders not_found' do
        get_terminal(id: 1234)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_terminal(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      get :terminal, params: params.merge(extra_params)
    end
  end

  describe 'GET #terminal_websocket_authorize' do
    let!(:job) { create(:ci_build, :running, :with_runner_session, pipeline: pipeline) }

    before do
      project.add_developer(user)
      sign_in(user)
    end

    context 'with valid workhorse signature' do
      before do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)
      end

      context 'and valid id' do
        it 'returns the terminal for the job' do
          expect(Gitlab::Workhorse)
            .to receive(:channel_websocket)
            .and_return(workhorse: :response)

          get_terminal_websocket(id: job.id)

          expect(response).to have_gitlab_http_status(200)
          expect(response.headers["Content-Type"]).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(response.body).to eq('{"workhorse":"response"}')
        end
      end

      context 'and invalid id' do
        it 'returns 404' do
          get_terminal_websocket(id: 1234)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'with invalid workhorse signature' do
      it 'aborts with an exception' do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_raise(JWT::DecodeError)

        expect { get_terminal_websocket(id: job.id) }.to raise_error(JWT::DecodeError)
      end
    end

    def get_terminal_websocket(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      get :terminal_websocket_authorize, params: params.merge(extra_params)
    end
  end
end
