# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::RunnersController, feature_category: :runner_fleet do
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

    it 'shows a runner show page' do
      get :show, params: { id: runner.id }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:show)
    end
  end

  describe '#new' do
    it 'renders a :new template' do
      get :new

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:new)
    end

    context 'when create_runner_workflow_for_admin is disabled' do
      before do
        stub_feature_flags(create_runner_workflow_for_admin: false)
      end

      it 'returns :not_found' do
        get :new

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#register' do
    subject(:register) { get :register, params: { id: new_runner.id } }

    context 'when runner can be registered after creation' do
      let_it_be(:new_runner) { create(:ci_runner, registration_type: :authenticated_user) }

      it 'renders a :register template' do
        register

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:register)
      end
    end

    context 'when runner cannot be registered after creation' do
      let_it_be(:new_runner) { runner }

      it 'returns :not_found' do
        register

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when create_runner_workflow_for_admin is disabled' do
      let_it_be(:new_runner) { create(:ci_runner, registration_type: :authenticated_user) }

      before do
        stub_feature_flags(create_runner_workflow_for_admin: false)
      end

      it 'returns :not_found' do
        register

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#edit' do
    render_views

    let_it_be(:project) { create(:project) }
    let_it_be(:project_two) { create(:project) }

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

      # There is one additional query looking up subject.group in ProjectPolicy for the
      # needs_new_sso_session permission
      expect { get :edit, params: { id: runner.id } }.not_to exceed_query_limit(control_count + 1)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe '#update' do
    let(:new_desc) { runner.description.swapcase }
    let(:runner_params) { { id: runner.id, runner: { description: new_desc } } }

    subject(:request) { post :update, params: runner_params }

    context 'with update succeeding' do
      before do
        expect_next_instance_of(Ci::Runners::UpdateRunnerService, runner) do |service|
          expect(service).to receive(:execute).with(anything).and_call_original
        end
      end

      it 'updates the runner and ticks the queue' do
        expect { request }.to change { runner.ensure_runner_queue_value }

        runner.reload

        expect(response).to have_gitlab_http_status(:found)
        expect(runner.description).to eq(new_desc)
      end
    end

    context 'with update failing' do
      before do
        expect_next_instance_of(Ci::Runners::UpdateRunnerService, runner) do |service|
          expect(service).to receive(:execute).with(anything).and_return(ServiceResponse.error(message: 'failure'))
        end
      end

      it 'does not update runner or tick the queue' do
        expect { request }.not_to change { runner.ensure_runner_queue_value }
        expect { request }.not_to change { runner.reload.description }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end
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
