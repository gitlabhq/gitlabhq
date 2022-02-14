# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::RunnersController do
  let_it_be(:runner) { create(:ci_runner) }
  let_it_be(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  describe '#index' do
    render_views

    before do
      get :index
    end

    it 'renders index template' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end
  end

  describe '#show' do
    render_views

    let_it_be(:project) { create(:project) }

    before_all do
      create(:ci_build, runner: runner, project: project)
    end

    it 'shows a runner show page' do
      get :show, params: { id: runner.id }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:show)
    end

    it 'when runner_read_only_admin_view is off, redirects to the runner edit page' do
      stub_feature_flags(runner_read_only_admin_view: false)

      get :show, params: { id: runner.id }

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to edit_admin_runner_path(runner)
    end
  end

  describe '#edit' do
    render_views

    let_it_be(:project) { create(:project) }
    let_it_be(:project_two) { create(:project) }

    before_all do
      create(:ci_build, runner: runner, project: project)
      create(:ci_build, runner: runner, project: project_two)
    end

    it 'shows a runner edit page' do
      get :edit, params: { id: runner.id }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'shows 404 for unknown runner' do
      get :edit, params: { id: 0 }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'avoids N+1 queries', :request_store do
      get :edit, params: { id: runner.id }

      control_count = ActiveRecord::QueryRecorder.new { get :edit, params: { id: runner.id } }.count

      new_project = create(:project)
      create(:ci_build, runner: runner, project: new_project)

      # There is one additional query looking up subject.group in ProjectPolicy for the
      # needs_new_sso_session permission
      expect { get :edit, params: { id: runner.id } }.not_to exceed_query_limit(control_count + 1)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe '#update' do
    it 'updates the runner and ticks the queue' do
      new_desc = runner.description.swapcase

      expect do
        post :update, params: { id: runner.id, runner: { description: new_desc } }
      end.to change { runner.ensure_runner_queue_value }

      runner.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(runner.description).to eq(new_desc)
    end
  end

  describe '#destroy' do
    it 'destroys the runner' do
      expect_next_instance_of(Ci::UnregisterRunnerService, runner) do |service|
        expect(service).to receive(:execute).once.and_call_original
      end

      delete :destroy, params: { id: runner.id }

      expect(response).to have_gitlab_http_status(:found)
      expect(Ci::Runner.find_by(id: runner.id)).to be_nil
    end
  end

  describe '#resume' do
    it 'marks the runner as active and ticks the queue' do
      runner.update!(active: false)

      expect do
        post :resume, params: { id: runner.id }
      end.to change { runner.ensure_runner_queue_value }

      runner.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(runner.active).to eq(true)
    end
  end

  describe '#pause' do
    it 'marks the runner as inactive and ticks the queue' do
      runner.update!(active: true)

      expect do
        post :pause, params: { id: runner.id }
      end.to change { runner.ensure_runner_queue_value }

      runner.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(runner.active).to eq(false)
    end
  end

  describe 'GET #runner_setup_scripts' do
    it 'renders the setup scripts' do
      get :runner_setup_scripts, params: { os: 'linux', arch: 'amd64' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to have_key("install")
      expect(json_response).to have_key("register")
    end

    it 'renders errors if they occur' do
      get :runner_setup_scripts, params: { os: 'foo', arch: 'bar' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response).to have_key("errors")
    end
  end
end
