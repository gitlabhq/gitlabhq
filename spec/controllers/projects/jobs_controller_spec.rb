require 'spec_helper'

describe Projects::JobsController do
  include ApiHelpers

  let(:project) { create(:project, :public) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:user) { create(:user) }

  before do
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
      before do
        Ci::Build::AVAILABLE_STATUSES.each do |status|
          create_job(status, status)
        end
      end

      it 'verifies number of queries', :request_store do
        recorded = ActiveRecord::QueryRecorder.new { get_index }
        expect(recorded.count).to be_within(5).of(7)
      end

      def create_job(name, status)
        pipeline = create(:ci_pipeline, project: project)
        create(:ci_build, :tags, :triggered, :artifacts,
          pipeline: pipeline, name: name, status: status)
      end
    end

    def get_index(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      get :index, params.merge(extra_params)
    end
  end

  describe 'GET show' do
    let!(:job) { create(:ci_build, :failed, pipeline: pipeline) }

    context 'when requesting HTML' do
      context 'when job exists' do
        before do
          get_show(id: job.id)
        end

        it 'has a job' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:build).id).to eq(job.id)
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

        allow_any_instance_of(Ci::Build).to receive(:merge_request).and_return(merge_request)

        get_show(id: job.id, format: :json)
      end

      it 'exposes needed information' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['raw_path']).to match(%r{jobs/\d+/raw\z})
        expect(json_response.dig('merge_request', 'path')).to match(%r{merge_requests/\d+\z})
        expect(json_response['new_issue_path'])
          .to include('/issues/new')
      end
    end

    def get_show(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      get :show, params.merge(extra_params)
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
        expect(json_response['id']).to eq job.id
        expect(json_response['status']).to eq job.status
        expect(json_response['html']).to eq(job.trace.html)
      end
    end

    context 'when job has a trace' do
      let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

      it 'returns a trace' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq job.id
        expect(json_response['status']).to eq job.status
        expect(json_response['html']).to eq('BUILD TRACE')
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

    def get_trace
      get :trace, namespace_id: project.namespace,
                  project_id: project,
                  id: job.id,
                  format: :json
    end
  end

  describe 'GET status.json' do
    let(:job) { create(:ci_build, pipeline: pipeline) }
    let(:status) { job.detailed_status(double('user')) }

    before do
      get :status, namespace_id: project.namespace,
                   project_id: project,
                   id: job.id,
                   format: :json
    end

    it 'return a detailed job status in json' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['text']).to eq status.text
      expect(json_response['label']).to eq status.label
      expect(json_response['icon']).to eq status.icon
      expect(json_response['favicon']).to match_asset_path "/assets/ci_favicons/#{status.favicon}.ico"
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
      post :retry, namespace_id: project.namespace,
                   project_id: project,
                   id: job.id
    end
  end

  describe 'POST play' do
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
    end

    context 'when job is not playable' do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'renders unprocessable_entity' do
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    def post_play
      post :play, namespace_id: project.namespace,
                  project_id: project,
                  id: job.id
    end
  end

  describe 'POST cancel' do
    before do
      project.add_developer(user)
      sign_in(user)

      post_cancel
    end

    context 'when job is cancelable' do
      let(:job) { create(:ci_build, :cancelable, pipeline: pipeline) }

      it 'redirects to the canceled job page' do
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_job_path(id: job.id))
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

    def post_cancel
      post :cancel, namespace_id: project.namespace,
                    project_id: project,
                    id: job.id
    end
  end

  describe 'POST cancel_all' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    context 'when jobs are cancelable' do
      before do
        create_list(:ci_build, 2, :cancelable, pipeline: pipeline)

        post_cancel_all
      end

      it 'redirects to a index page' do
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_jobs_path)
      end

      it 'transits to canceled' do
        expect(Ci::Build.all).to all(be_canceled)
      end
    end

    context 'when jobs are not cancelable' do
      before do
        create_list(:ci_build, 2, :canceled, pipeline: pipeline)

        post_cancel_all
      end

      it 'redirects to a index page' do
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_jobs_path)
      end
    end

    def post_cancel_all
      post :cancel_all, namespace_id: project.namespace,
                        project_id: project
    end
  end

  describe 'POST erase' do
    let(:role) { :master }

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
        expect(job.artifacts_file.exists?).to be_falsey
        expect(job.artifacts_metadata.exists?).to be_falsey
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
      post :erase, namespace_id: project.namespace,
                   project_id: project,
                   id: job.id
    end
  end

  describe 'GET raw' do
    before do
      get_raw
    end

    context 'when job has a trace artifact' do
      let(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

      it 'returns a trace' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.content_type).to eq 'text/plain; charset=utf-8'
        expect(response.body).to eq job.job_artifacts_trace.open.read
      end
    end

    context 'when job has a trace file' do
      let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

      it 'send a trace file' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.content_type).to eq 'text/plain; charset=utf-8'
        expect(response.body).to eq 'BUILD TRACE'
      end
    end

    context 'when job does not have a trace file' do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'returns not_found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_raw
      post :raw, namespace_id: project.namespace,
                 project_id: project,
                 id: job.id
    end
  end
end
