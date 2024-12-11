# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::JobsController, :clean_gitlab_redis_shared_state, feature_category: :continuous_integration, factory_default: :keep do
  include ApiHelpers
  include HttpIOHelpers

  let_it_be(:namespace) { create_default(:namespace) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:owner) { create(:owner) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }

  before_all do
    project.update!(ci_pipeline_variables_minimum_override_role: :developer)
    project.add_owner(owner)
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
    project.add_guest(guest)
    create_default(:owner)
    create_default(:user)
    create_default(:ci_trigger_request, project_id: project.id)
    create_default(:ci_stage)
  end

  let(:user) { developer }

  let_it_be_with_reload(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:default_pipeline) { create_default(:ci_pipeline) }

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
      end
    end

    context 'when scope is running' do
      before do
        create(:ci_build, :running, pipeline: pipeline)

        get_index(scope: 'running')
      end

      it 'has only running jobs' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when scope is finished' do
      before do
        create(:ci_build, :success, pipeline: pipeline)

        get_index(scope: 'finished')
      end

      it 'has only finished jobs' do
        expect(response).to have_gitlab_http_status(:ok)
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
        create(
          :ci_build, :tags, :triggered, :artifacts,
          pipeline: pipeline, name: name, status: status, user: user
        )
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
        let(:extra_params) { { id: job.id } }

        it 'has a job' do
          get_show(**extra_params)

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:build).id).to eq(job.id)
        end
      end

      context 'when job does not exist' do
        before do
          get_show(id: non_existing_record_id)
        end

        it 'renders not_found' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the job is a bridge' do
        let!(:downstream_pipeline) { create(:ci_pipeline, child_of: pipeline) }
        let(:job) { downstream_pipeline.source_job }

        it 'redirects to the downstream pipeline page' do
          get_show(id: job.id)

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(namespace_project_pipeline_path(id: downstream_pipeline.id))
        end
      end
    end

    context 'when requesting JSON' do
      let(:user) { developer }

      before do
        sign_in(user)

        allow_any_instance_of(Ci::Build)
          .to receive(:merge_request)
          .and_return(merge_request)
      end

      it 'does not serialize builds in exposed stages' do
        get_show_json

        json_response.dig('pipeline', 'details', 'stages').tap do |stages|
          expect(stages.flat_map(&:keys))
            .to eq %w[name id title status path dropdown_path]
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

      it "avoids N+1 database queries", :use_sql_query_cache do
        get_show_json

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { get_show_json }

        create_list(:ci_build, 5, :failed, pipeline: pipeline)

        expect { get_show_json }.to issue_same_number_of_queries_as(control)
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
          let(:job) { create(:ci_build, :running, :with_runner_session, pipeline: pipeline, user: user) }

          it 'exposes the terminal path' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
            expect(json_response['terminal_path']).to match(%r{/terminal})
          end
        end
      end

      context 'when job has artifacts' do
        let_it_be(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

        context 'with not expiry date' do
          context 'when artifacts are unlocked' do
            before do
              job.pipeline.unlocked!
            end

            it 'exposes needed information' do
              get_show_json

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to match_response_schema('job/job_details')
              expect(json_response['artifact']['download_path']).to match(%r{artifacts/download})
              expect(json_response['artifact']['browse_path']).to match(%r{artifacts/browse})
              expect(json_response['artifact']).not_to have_key('keep_path')
              expect(json_response['artifact']).not_to have_key('expired')
              expect(json_response['artifact']).not_to have_key('expired_at')
            end
          end

          context 'when artifacts are locked' do
            before do
              job.pipeline.reload.artifacts_locked!
            end

            it 'exposes needed information' do
              get_show_json

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to match_response_schema('job/job_details')
              expect(json_response['artifact']['download_path']).to match(%r{artifacts/download})
              expect(json_response['artifact']['browse_path']).to match(%r{artifacts/browse})
              expect(json_response['artifact']).not_to have_key('keep_path')
              expect(json_response['artifact']).not_to have_key('expired')
              expect(json_response['artifact']).not_to have_key('expired_at')
            end
          end
        end

        context 'with expired artifacts' do
          before do
            job.update!(artifacts_expire_at: 1.minute.ago)
          end

          context 'when artifacts are unlocked' do
            before do
              job.pipeline.reload.unlocked!
            end

            it 'exposes needed information' do
              get_show_json

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to match_response_schema('job/job_details')
              expect(json_response['artifact']).not_to have_key('download_path')
              expect(json_response['artifact']).not_to have_key('browse_path')
              expect(json_response['artifact']).not_to have_key('keep_path')
              expect(json_response['artifact']['expired']).to eq(true)
              expect(json_response['artifact']['expire_at']).not_to be_empty
              expect(json_response['artifact']['locked']).to eq(false)
            end
          end

          context 'when artifacts are locked' do
            before do
              job.pipeline.reload.artifacts_locked!
            end

            it 'exposes needed information' do
              get_show_json

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to match_response_schema('job/job_details')
              expect(json_response['artifact']).to have_key('download_path')
              expect(json_response['artifact']).to have_key('browse_path')
              expect(json_response['artifact']).to have_key('keep_path')
              expect(json_response['artifact']['expired']).to eq(true)
              expect(json_response['artifact']['expire_at']).not_to be_empty
              expect(json_response['artifact']['locked']).to eq(true)
            end
          end
        end

        context 'when job passed with no trace' do
          it 'exposes empty state illustrations' do
            get_show_json

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
            expect(json_response['status']['illustration']).to have_key('image')
            expect(json_response['status']['illustration']).to have_key('size')
            expect(json_response['status']['illustration']).to have_key('title')
          end
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
        let(:environment) { create(:environment, project: project, name: 'staging', state: :available) }
        let(:job) { create(:ci_build, :running, environment: environment.name, pipeline: pipeline) }

        let(:user) { maintainer }

        before do
          create(:deployment, :success, :on_cluster, environment: environment, project: project)
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
          let(:user) { maintainer }

          before do
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
          let(:user) { maintainer }

          before do
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
          let(:user) { maintainer }

          before do
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
        let(:runner) { create(:ci_runner, :instance, :paused) }
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
          let(:user) { developer }

          it 'settings_path is not available' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('job/job_details')
            expect(json_response['runners']).not_to have_key('settings_path')
          end
        end

        context 'when user is maintainer' do
          let(:user) { admin }

          before do
            sign_in(user)
          end

          context 'when admin mode is disabled' do
            it 'settings_path is not available' do
              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to match_response_schema('job/job_details')
              expect(json_response['runners']).not_to have_key('settings_path')
            end
          end

          context 'when admin mode is enabled', :enable_admin_mode do
            it 'settings_path is available' do
              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to match_response_schema('job/job_details')
              expect(json_response['runners']['settings_path']).to match(/runners/)
            end
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

      context 'when job has live trace' do
        let(:job) { create(:ci_build, :running, :trace_live, pipeline: pipeline) }

        it 'has_trace is true' do
          get_show_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details')
          expect(json_response['has_trace']).to be true
        end
      end

      context 'when has live trace and unarchived artifact' do
        let(:job) { create(:ci_build, :running, :trace_live, :unarchived_trace_artifact, pipeline: pipeline) }

        it 'has_trace is true' do
          get_show_json

          expect(response).to have_gitlab_http_status(:ok)
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
      let(:trigger) { create(:ci_trigger, project: project) }
      let(:trigger_request) { create(:ci_trigger_request, pipeline: pipeline, trigger: trigger) }
      let(:job) { create(:ci_build, pipeline: pipeline, trigger_request: trigger_request) }
      let(:user) { developer }

      before do
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
          let(:user) { maintainer }

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
        .to change { Gitlab::GitalyClient.get_request_count }.by_at_most(3)
    end

    def get_show(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      get :show, params: params.merge(extra_params)
    end
  end

  describe 'GET test_report_summary.json' do
    let_it_be(:build) { create(:ci_build, :success, :test_reports, project: project) }

    before do
      sign_in(user)
    end

    context 'when the user has access' do
      let(:user) { developer }

      context 'when the summary has been generated' do
        let!(:report_result) { create(:ci_build_report_result, build: build, project: project) }

        before do
          get_test_report_summary
        end

        it 'returns the summary as json' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/test_report_summary')
        end
      end

      context 'when the summary has not been generated' do
        before do
          get_test_report_summary
        end

        it 'returns a 404 response' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when the user does not have access' do
      let(:user) { guest }

      before do
        project.update!(public_builds: false)
        get_test_report_summary
      end

      it 'returns not_found status' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_test_report_summary
      get :test_report_summary,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          id: build.id
        },
        format: :json
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

      context 'when debug_mode? is enabled' do
        before do
          allow_next_found_instance_of(Ci::Build) do |build|
            allow(build).to receive(:debug_mode?).and_return(true)
          end
        end

        context 'with proper permissions on a project' do
          let(:user) { developer }

          before do
            sign_in(user)
          end

          it 'returns response ok' do
            get_trace

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'without proper permissions for debug logging' do
          let(:user) { guest }

          before do
            sign_in(user)
          end

          it 'returns response forbidden' do
            get_trace

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end

    context 'when job has a live trace' do
      let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

      shared_examples_for 'returns trace' do
        it 'returns a trace' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/build_trace')
          expect(json_response['id']).to eq job.id
          expect(json_response['status']).to eq job.status
          expect(json_response['lines']).to match_array [{ 'content' => [{ 'text' => 'BUILD TRACE' }], 'offset' => 0 }]
        end
      end

      it_behaves_like 'returns trace'

      context 'when job has unarchived artifact' do
        let(:job) { create(:ci_build, :trace_live, :unarchived_trace_artifact, pipeline: pipeline) }

        it_behaves_like 'returns trace'
      end

      context 'when job is running' do
        let(:job) { create(:ci_build, :trace_live, :running, pipeline: pipeline) }

        it 'sets being-watched flag for the job' do
          expect(response).to have_gitlab_http_status(:ok)

          expect(job.trace.being_watched?).to be(true)
        end
      end

      context 'when job is not running' do
        it 'does not set being-watched flag for the job' do
          expect(response).to have_gitlab_http_status(:ok)

          expect(job.trace.being_watched?).to be(false)
        end
      end
    end

    context 'when job has no traces' do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'returns no traces' do
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when job has a trace with ANSI sequence and Unicode' do
      let(:job) { create(:ci_build, :unicode_trace_live, pipeline: pipeline) }

      it 'returns a trace with Unicode' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('job/build_trace')
        expect(json_response['id']).to eq job.id
        expect(json_response['status']).to eq job.status
        expect(json_response['lines'].flat_map { |l| l['content'].map { |c| c['text'] } }).to include("ヾ(´༎ຶД༎ຶ`)ﾉ")
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

  describe 'POST retry' do
    let(:user) { developer }

    before do
      sign_in(user)
    end

    context 'when job is not retryable' do
      context 'and the job is a bridge' do
        let(:job) { create(:ci_bridge, :failed, :reached_max_descendant_pipelines_depth, pipeline: pipeline) }

        it 'renders unprocessable_entity' do
          post_retry

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      context 'and the job is a build' do
        let(:job) { create(:ci_build, :deployment_rejected, pipeline: pipeline) }

        it 'renders unprocessable_entity' do
          post_retry

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when job is retryable' do
      context 'and the job is a bridge' do
        let(:job) { create(:ci_bridge, :retryable, pipeline: pipeline) }

        it 'responds :ok' do
          post_retry

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'and the job is a build' do
        let(:job) { create(:ci_build, :retryable, pipeline: pipeline) }

        it 'redirects to the retried job page' do
          post_retry

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(namespace_project_job_path(id: Ci::Build.last.id))
        end
      end

      shared_examples_for 'retried job has the same attributes' do
        it 'creates a new build has the same attributes from the previous build' do
          expect { post_retry }.to change { Ci::Build.count }.by(1)

          retried_build = Ci::Build.last

          Ci::Build.clone_accessors.each do |accessor|
            expect(job.read_attribute(accessor)).to eq(retried_build.read_attribute(accessor)),
              "Mismatched attribute on \"#{accessor}\". " \
              "It was \"#{job.read_attribute(accessor)}\" but changed to \"#{retried_build.read_attribute(accessor)}\""
          end
        end
      end

      context 'with branch pipeline' do
        let!(:job) { create(:ci_build, :retryable, tag: true, when: 'on_success', pipeline: pipeline) }

        it_behaves_like 'retried job has the same attributes'
      end

      context 'with tag pipeline' do
        let!(:job) { create(:ci_build, :retryable, tag: false, when: 'on_success', pipeline: pipeline) }

        it_behaves_like 'retried job has the same attributes'
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
    let(:user) { developer }

    before do
      project.add_developer(user)

      create(:protected_branch, :developers_can_merge, name: 'protected-branch', project: project)

      sign_in(user)
    end

    context 'when job is playable' do
      let(:job) { create(:ci_build, :playable, pipeline: pipeline) }

      it 'redirects to the played job page' do
        post_play

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_job_path(id: job.id))
      end

      it 'transits to pending' do
        post_play

        expect(job.reload).to be_pending
      end

      context 'when job variables are specified' do
        let(:variable_attributes) { [{ key: 'first', secret_value: 'first' }] }

        it 'assigns the job variables' do
          post_play

          expect(job.reload.job_variables.map(&:key)).to contain_exactly('first')
        end
      end

      context 'when job is bridge' do
        let(:downstream_project) { create(:project) }
        let(:job) { create(:ci_bridge, :playable, pipeline: pipeline, downstream: downstream_project) }

        before do
          downstream_project.add_developer(user)
        end

        it 'redirects to the pipeline page' do
          post_play

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(pipeline_path(pipeline))
          builds_namespace_project_pipeline_path(id: pipeline.id)
        end

        it 'transits to pending' do
          post_play

          expect(job.reload).to be_pending
        end
      end
    end

    context 'when job is not playable' do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'renders unprocessable_entity' do
        post_play

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
    context 'when user is authorized to cancel the build' do
      let(:user) { developer }

      before do
        sign_in(user)
      end

      context 'when continue url is present' do
        let(:job) { create(:ci_build, :cancelable, pipeline: pipeline) }

        before do
          post_cancel(continue: { to: url })
        end

        context 'when continue to is a safe url' do
          let(:url) { '/test' }

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

          it 'redirects to the builds page' do
            expect(response).to have_gitlab_http_status(:found)
            expect(response).to redirect_to(builds_namespace_project_pipeline_path(id: pipeline.id))
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
    end

    context 'when user is not authorized to cancel the build' do
      let!(:job) { create(:ci_build, :cancelable, pipeline: pipeline) }

      let(:user) { guest }

      before do
        sign_in(user)

        post_cancel
      end

      it 'responds with not_found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not transit to canceled' do
        expect(job.reload).not_to be_canceled
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
      create(:protected_branch, :developers_can_merge, name: 'protected-branch', project: project)
    end

    context 'when user is authorized to unschedule the build' do
      let(:user) { developer }

      before do
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
    end

    context 'when user is not authorized to unschedule the build' do
      let(:job) { create(:ci_build, :scheduled, pipeline: pipeline) }
      let(:user) { guest }

      before do
        sign_in(user)

        post_unschedule
      end

      it 'responds with not_found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not transit to scheduled' do
        expect(job.reload).not_to be_manual
      end
    end

    def post_unschedule
      post :unschedule, params: { namespace_id: project.namespace, project_id: project, id: job.id }
    end
  end

  describe 'POST erase' do
    let(:user) { maintainer }

    before do
      sign_in(user)
    end

    context 'when project is not undergoing stats refresh' do
      before do
        post_erase
      end

      shared_examples_for 'erases' do
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

      context 'when job is successful and has artifacts' do
        let(:job) { create(:ci_build, :erasable, :trace_artifact, pipeline: pipeline) }

        it_behaves_like 'erases'
      end

      context 'when job has live trace and unarchived artifact' do
        let(:job) { create(:ci_build, :success, :trace_live, :unarchived_trace_artifact, pipeline: pipeline) }

        it_behaves_like 'erases'
      end

      context 'when job is erased' do
        let(:job) { create(:ci_build, :erased, pipeline: pipeline) }

        it 'returns unprocessable_entity' do
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      context 'when user is developer' do
        let(:user) { developer }
        let(:job) { create(:ci_build, :erasable, :trace_artifact, pipeline: pipeline, user: triggered_by) }

        context 'when triggered by same user' do
          let(:triggered_by) { user }

          it 'has successful status' do
            expect(response).to have_gitlab_http_status(:found)
          end
        end

        context 'when triggered by different user' do
          let(:triggered_by) { maintainer }

          it 'does not have successful status' do
            expect(response).not_to have_gitlab_http_status(:found)
          end
        end
      end
    end

    context 'when project is undergoing stats refresh' do
      it_behaves_like 'preventing request because of ongoing project stats refresh' do
        let(:job) { create(:ci_build, :erasable, :trace_artifact, pipeline: pipeline) }
        let(:make_request) { post_erase }

        it 'does not erase artifacts' do
          make_request

          expect(job.artifacts_file).to be_present
          expect(job.artifacts_metadata).to be_present
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

    context 'when job has a trace artifact' do
      let(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

      it "sets #{Gitlab::Workhorse::DETECT_HEADER} header" do
        response = subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers["Content-Type"]).to eq("text/plain; charset=utf-8")
        expect(response.body).to eq(job.job_artifacts_trace.open.read)
        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
      end

      context 'when CI_DEBUG_TRACE and/or CI_DEBUG_SERVICES are enabled' do
        using RSpec::Parameterized::TableSyntax
        where(:ci_debug_trace, :ci_debug_services) do
          true  | true
          true  | false
          false | true
          false | false
        end

        with_them do
          before do
            create(:ci_instance_variable, key: 'CI_DEBUG_TRACE', value: ci_debug_trace)
            create(:ci_instance_variable, key: 'CI_DEBUG_SERVICES', value: ci_debug_services)
          end

          context 'with proper permissions for debug logging on a project' do
            let(:user) { developer }

            before do
              sign_in(user)
            end

            it 'returns response ok' do
              response = subject

              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          context 'without proper permissions for debug logging on a project' do
            let(:user) { reporter }

            before do
              sign_in(user)
            end

            it 'returns response forbidden if dev mode enabled' do
              response = subject

              if ci_debug_trace || ci_debug_services
                expect(response).to have_gitlab_http_status(:forbidden)
              else
                expect(response).to have_gitlab_http_status(:ok)
              end
            end
          end
        end
      end
    end

    context 'when job has a live trace' do
      let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

      shared_examples_for 'sends live trace' do
        it 'sends a trace file' do
          response = subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers["Content-Type"]).to eq("text/plain; charset=utf-8")
          expect(response.headers["Content-Disposition"]).to match(/^inline/)
          expect(response.body).to eq("BUILD TRACE")
        end
      end

      it_behaves_like 'sends live trace'

      context 'and when job has unarchived artifact' do
        let(:job) { create(:ci_build, :trace_live, :unarchived_trace_artifact, pipeline: pipeline) }

        it_behaves_like 'sends live trace'
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
    let(:user) { developer }

    before do
      sign_in(user)
    end

    context 'when job exists' do
      context 'and it has a terminal' do
        let!(:job) { create(:ci_build, :running, :with_runner_session, pipeline: pipeline, user: user) }

        it 'has a job' do
          get_terminal(id: job.id)

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:build).id).to eq(job.id)
        end
      end

      context 'and does not have a terminal' do
        let!(:job) { create(:ci_build, :running, pipeline: pipeline, user: user) }

        it 'returns not_found' do
          get_terminal(id: job.id)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when job does not exist' do
      it 'renders not_found' do
        get_terminal(id: non_existing_record_id)

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
    let!(:job) { create(:ci_build, :running, :with_runner_session, pipeline: pipeline, user: user) }

    let(:user) { developer }

    before do
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

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers["Content-Type"]).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(response.body).to eq('{"workhorse":"response"}')
        end
      end

      context 'and invalid id' do
        it 'returns 404' do
          get_terminal_websocket(id: non_existing_record_id)

          expect(response).to have_gitlab_http_status(:not_found)
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

  describe 'GET #proxy_websocket_authorize' do
    let(:user) { maintainer }
    let(:pipeline) { create(:ci_pipeline, project: project, source: :webide, config_source: :webide_source, user: user) }
    let(:job) { create(:ci_build, :running, :with_runner_session, pipeline: pipeline, user: user) }
    let(:extra_params) { { id: job.id } }
    let(:path) { :proxy_websocket_authorize }
    let(:render_method) { :channel_websocket }
    let(:expected_data) do
      {
        'Channel' => {
          'Subprotocols' => ["terminal.gitlab.com"],
          'Url' => 'wss://gitlab.example.com/proxy/build/default_port/',
          'Header' => {
            'Authorization' => [nil]
          },
          'MaxSessionTime' => nil,
          'CAPem' => nil
        }
      }.to_json
    end

    before do
      stub_feature_flags(build_service_proxy: true)
      allow(job).to receive(:has_terminal?).and_return(true)

      sign_in(user)
    end

    context 'access rights' do
      before do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)

        make_request
      end

      context 'with admin' do
        let(:user) { admin }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'returns 200' do
            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when admin mode is disabled' do
          it 'returns 404' do
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'with owner' do
        let(:user) { owner }

        it 'returns 200' do
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with maintainer' do
        let(:user) { maintainer }

        it 'returns 200' do
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with developer' do
        let(:user) { developer }

        it 'returns 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with reporter' do
        let(:user) { reporter }

        it 'returns 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with guest' do
        let(:user) { guest }

        it 'returns 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with non member' do
        let(:user) { create(:user) }

        it 'returns 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when pipeline is not from a webide source' do
      context 'with admin' do
        let(:user) { admin }
        let(:pipeline) { create(:ci_pipeline, project: project, source: :chat, user: user) }

        before do
          allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)
          make_request
        end

        it 'returns 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when workhorse signature is valid' do
      before do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)
      end

      context 'and the id is valid' do
        it 'returns the proxy data for the service running in the job' do
          make_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers["Content-Type"]).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(response.body).to eq(expected_data)
        end
      end

      context 'and the id is invalid' do
        let(:extra_params) { { id: non_existing_record_id } }

        it 'returns 404' do
          make_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with invalid workhorse signature' do
      it 'aborts with an exception' do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_raise(JWT::DecodeError)

        expect { make_request }.to raise_error(JWT::DecodeError)
      end
    end

    context 'when feature flag :build_service_proxy is disabled' do
      let(:user) { admin }

      it 'returns 404' do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)
        stub_feature_flags(build_service_proxy: false)

        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'converts the url scheme into wss' do
      allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)

      expect(job.runner_session_url).to start_with('https://')
      expect(Gitlab::Workhorse).to receive(:channel_websocket)
        .with(a_hash_including(url: "wss://gitlab.example.com/proxy/build/default_port/"))

      make_request
    end

    def make_request
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      get path, params: params.merge(extra_params)
    end
  end
end
