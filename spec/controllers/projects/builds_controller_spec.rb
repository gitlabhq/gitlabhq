require 'spec_helper'

describe Projects::BuildsController do
  include ApiHelpers

  let(:project) { create(:empty_project, :public) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:user) { create(:user) }

  describe 'GET index' do
    context 'when scope is pending' do
      before do
        create(:ci_build, :pending, pipeline: pipeline)

        get_index(scope: 'pending')
      end

      it 'has only pending builds' do
        expect(response).to have_http_status(:ok)
        expect(assigns(:builds).first.status).to eq('pending')
      end
    end

    context 'when scope is running' do
      before do
        create(:ci_build, :running, pipeline: pipeline)

        get_index(scope: 'running')
      end

      it 'has only running builds' do
        expect(response).to have_http_status(:ok)
        expect(assigns(:builds).first.status).to eq('running')
      end
    end

    context 'when scope is finished' do
      before do
        create(:ci_build, :success, pipeline: pipeline)

        get_index(scope: 'finished')
      end

      it 'has only finished builds' do
        expect(response).to have_http_status(:ok)
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
          expect(response).to have_http_status(:ok)
          expect(assigns(:builds).current_page).to eq(last_page)
        end
      end
    end

    context 'number of queries' do
      before do
        Ci::Build::AVAILABLE_STATUSES.each do |status|
          create_build(status, status)
        end

        RequestStore.begin!
      end

      after do
        RequestStore.end!
        RequestStore.clear!
      end

      it "verifies number of queries" do
        recorded = ActiveRecord::QueryRecorder.new { get_index }
        expect(recorded.count).to be_within(5).of(8)
      end

      def create_build(name, status)
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
    context 'when build exists' do
      let!(:build) { create(:ci_build, pipeline: pipeline) }

      before do
        get_show(id: build.id)
      end

      it 'has a build' do
        expect(response).to have_http_status(:ok)
        expect(assigns(:build).id).to eq(build.id)
      end
    end

    context 'when build does not exist' do
      before do
        get_show(id: 1234)
      end

      it 'renders not_found' do
        expect(response).to have_http_status(:not_found)
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

    context 'when build has a trace' do
      let(:build) { create(:ci_build, :trace, pipeline: pipeline) }

      it 'returns a trace' do
        expect(response).to have_http_status(:ok)
        expect(json_response['html']).to eq('BUILD TRACE')
      end
    end

    context 'when build has no traces' do
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it 'returns no traces' do
        expect(response).to have_http_status(:ok)
        expect(json_response['html']).to be_nil
      end
    end

    def get_trace
      get :trace, namespace_id: project.namespace,
                  project_id: project,
                  id: build.id,
                  format: :json
    end
  end

  describe 'GET status.json' do
    let(:build) { create(:ci_build, pipeline: pipeline) }
    let(:status) { build.detailed_status(double('user')) }

    before do
      get :status, namespace_id: project.namespace,
                   project_id: project,
                   id: build.id,
                   format: :json
    end

    it 'return a detailed build status in json' do
      expect(response).to have_http_status(:ok)
      expect(json_response['text']).to eq status.text
      expect(json_response['label']).to eq status.label
      expect(json_response['icon']).to eq status.icon
      expect(json_response['favicon']).to eq "/assets/ci_favicons/#{status.favicon}.ico"
    end
  end

  describe 'GET trace.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build) { create(:ci_build, pipeline: pipeline) }
    let(:user) { create(:user) }

    context 'when user is logged in as developer' do
      before do
        project.add_developer(user)
        sign_in(user)

        get_trace
      end

      it 'traces build log' do
        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq build.id
        expect(json_response['status']).to eq build.status
      end
    end

    context 'when user is logged in as non member' do
      before do
        sign_in(user)

        get_trace
      end

      it 'traces build log' do
        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq build.id
        expect(json_response['status']).to eq build.status
      end
    end

    def get_trace
      get :trace, namespace_id: project.namespace,
                  project_id: project,
                  id: build.id,
                  format: :json
    end
  end

  describe 'POST retry' do
    before do
      project.add_developer(user)
      sign_in(user)

      post_retry
    end

    context 'when build is retryable' do
      let(:build) { create(:ci_build, :retryable, pipeline: pipeline) }

      it 'redirects to the retried build page' do
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(namespace_project_build_path(id: Ci::Build.last.id))
      end
    end

    context 'when build is not retryable' do
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it 'renders unprocessable_entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    def post_retry
      post :retry, namespace_id: project.namespace,
                   project_id: project,
                   id: build.id
    end
  end

  describe 'POST play' do
    before do
      project.add_master(user)
      sign_in(user)

      post_play
    end

    context 'when build is playable' do
      let(:build) { create(:ci_build, :playable, pipeline: pipeline) }

      it 'redirects to the played build page' do
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(namespace_project_build_path(id: build.id))
      end

      it 'transits to pending' do
        expect(build.reload).to be_pending
      end
    end

    context 'when build is not playable' do
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it 'renders unprocessable_entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    def post_play
      post :play, namespace_id: project.namespace,
                  project_id: project,
                  id: build.id
    end
  end

  describe 'POST cancel' do
    before do
      project.add_developer(user)
      sign_in(user)

      post_cancel
    end

    context 'when build is cancelable' do
      let(:build) { create(:ci_build, :cancelable, pipeline: pipeline) }

      it 'redirects to the canceled build page' do
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(namespace_project_build_path(id: build.id))
      end

      it 'transits to canceled' do
        expect(build.reload).to be_canceled
      end
    end

    context 'when build is not cancelable' do
      let(:build) { create(:ci_build, :canceled, pipeline: pipeline) }

      it 'returns unprocessable_entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    def post_cancel
      post :cancel, namespace_id: project.namespace,
                    project_id: project,
                    id: build.id
    end
  end

  describe 'POST cancel_all' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    context 'when builds are cancelable' do
      before do
        create_list(:ci_build, 2, :cancelable, pipeline: pipeline)

        post_cancel_all
      end

      it 'redirects to a index page' do
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(namespace_project_builds_path)
      end

      it 'transits to canceled' do
        expect(Ci::Build.all).to all(be_canceled)
      end
    end

    context 'when builds are not cancelable' do
      before do
        create_list(:ci_build, 2, :canceled, pipeline: pipeline)

        post_cancel_all
      end

      it 'redirects to a index page' do
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(namespace_project_builds_path)
      end
    end

    def post_cancel_all
      post :cancel_all, namespace_id: project.namespace,
                        project_id: project
    end
  end

  describe 'POST erase' do
    before do
      project.add_developer(user)
      sign_in(user)

      post_erase
    end

    context 'when build is erasable' do
      let(:build) { create(:ci_build, :erasable, :trace, pipeline: pipeline) }

      it 'redirects to the erased build page' do
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(namespace_project_build_path(id: build.id))
      end

      it 'erases artifacts' do
        expect(build.artifacts_file.exists?).to be_falsey
        expect(build.artifacts_metadata.exists?).to be_falsey
      end

      it 'erases trace' do
        expect(build.trace.exist?).to be_falsey
      end
    end

    context 'when build is not erasable' do
      let(:build) { create(:ci_build, :erased, pipeline: pipeline) }

      it 'returns unprocessable_entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    def post_erase
      post :erase, namespace_id: project.namespace,
                   project_id: project,
                   id: build.id
    end
  end

  describe 'GET raw' do
    before do
      get_raw
    end

    context 'when build has a trace file' do
      let(:build) { create(:ci_build, :trace, pipeline: pipeline) }

      it 'send a trace file' do
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq 'text/plain; charset=utf-8'
        expect(response.body).to eq 'BUILD TRACE'
      end
    end

    context 'when build does not have a trace file' do
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it 'returns not_found' do
        expect(response).to have_http_status(:not_found)
      end
    end

    def get_raw
      post :raw, namespace_id: project.namespace,
                 project_id: project,
                 id: build.id
    end
  end
end
