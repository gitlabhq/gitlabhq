# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RunnersController, feature_category: :fleet_visibility do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:another_project) { create(:project) }
  let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }

  let(:params) do
    {
      namespace_id: project.namespace,
      project_id: project,
      id: runner
    }
  end

  before do
    sign_in(user)
  end

  describe '#show' do
    context 'when user is maintainer' do
      before_all do
        project.add_maintainer(user)
      end

      it 'renders show with 200 status code' do
        get :show, params: params

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'with an instance runner' do
        let(:runner) { create(:ci_runner, :instance) }

        it 'renders show with 200 status code' do
          get :show, params: params

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when user is not maintainer' do
      before_all do
        project.add_developer(user)
      end

      it 'renders a 404' do
        get :show, params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'with an instance runner' do
        let(:runner) { create(:ci_runner, :instance) }

        it 'renders a 404' do
          get :show, params: params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe '#new' do
    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project
      }
    end

    context 'when user is maintainer' do
      before_all do
        project.add_maintainer(user)
      end

      it 'renders new with 200 status code' do
        get :new, params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:new)
      end
    end

    context 'when user is not maintainer' do
      before_all do
        project.add_developer(user)
      end

      it 'renders a 404' do
        get :new, params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#register', :freeze_time do
    subject(:register) do
      get :register, params: { namespace_id: project.namespace, project_id: project, id: new_runner }
    end

    let(:new_runner) do
      create(
        :ci_runner, :unregistered, *runner_traits, :project, projects: [project], registration_type: :authenticated_user
      )
    end

    context 'when user is maintainer' do
      before_all do
        project.add_maintainer(user)
      end

      context 'when runner can be registered after creation' do
        let(:runner_traits) { [:created_before_registration_deadline] }

        it 'renders a :register template' do
          register

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:register)
        end
      end

      context 'when runner cannot be registered after creation' do
        let(:runner_traits) { [:created_after_registration_deadline] }

        it 'returns :not_found' do
          register

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when user is not maintainer' do
      before_all do
        project.add_developer(user)
      end

      context 'when runner can be registered after creation' do
        let(:runner_traits) { [:created_before_registration_deadline] }

        it 'returns :not_found' do
          register

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe '#destroy' do
    before_all do
      project.add_maintainer(user)
    end

    it 'destroys the runner' do
      expect_next_instance_of(Ci::Runners::UnregisterRunnerService, runner, user) do |service|
        expect(service).to receive(:execute).once.and_call_original
      end

      delete :destroy, params: params

      expect(response).to have_gitlab_http_status(:found)
      expect(Ci::Runner.find_by(id: runner.id)).to be_nil
    end

    context 'with an instance runner' do
      let_it_be(:runner) { create(:ci_runner, :instance) }

      it 'does not allow deleting the runner' do
        delete :destroy, params: params

        expect(response).to have_gitlab_http_status(:not_found)
        expect(Ci::Runner.exists?(runner.id)).to be_truthy
      end
    end

    context 'with a project runner the user does not manage' do
      let(:runner) { create(:ci_runner, :project, projects: [another_project]) }

      it 'does not allow deleting the runner' do
        delete :destroy, params: params

        expect(response).to have_gitlab_http_status(:not_found)
        expect(Ci::Runner.exists?(runner.id)).to be_truthy
      end
    end
  end

  describe '#resume' do
    before_all do
      project.add_maintainer(user)
    end

    it 'marks the runner as active and ticks the queue' do
      runner.update!(active: false)

      expect do
        post :resume, params: params
      end.to change { runner.ensure_runner_queue_value }

      runner.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(runner.active).to eq(true)
    end
  end

  describe '#pause' do
    before_all do
      project.add_maintainer(user)
    end

    before do
      runner.update!(active: true)
    end

    it 'marks the runner as inactive and ticks the queue' do
      expect do
        post :pause, params: params
      end.to change { runner.ensure_runner_queue_value }

      runner.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(runner.active).to eq(false)
    end

    context 'with an instance runner' do
      let_it_be(:runner) { create(:ci_runner, :instance) }

      it 'does not allow pausing the runner' do
        post :pause, params: params

        expect(response).to have_gitlab_http_status(:not_found)
        expect(runner.active).to eq(true)
      end
    end

    context 'with a project runner the user does not manage' do
      let(:runner) { create(:ci_runner, :project, projects: [another_project]) }

      it 'does not allow pausing the runner' do
        post :pause, params: params

        expect(response).to have_gitlab_http_status(:not_found)
        expect(runner.active).to eq(true)
      end
    end
  end

  describe '#toggle_shared_runners' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }

    before do
      project.add_maintainer(user) # rubocop: disable RSpec/BeforeAllRoleAssignment
    end

    it 'toggles shared_runners_enabled when the group allows shared runners' do
      project.update!(shared_runners_enabled: true)

      post :toggle_shared_runners, params: params

      project.reload

      expect(response).to have_gitlab_http_status(:ok)
      expect(project.shared_runners_enabled).to eq(false)
    end

    it 'toggles shared_runners_enabled when the group disallows shared runners but allows overrides' do
      group.update!(shared_runners_enabled: false, allow_descendants_override_disabled_shared_runners: true)
      project.update!(shared_runners_enabled: false)

      post :toggle_shared_runners, params: params

      project.reload

      expect(response).to have_gitlab_http_status(:ok)
      expect(project.shared_runners_enabled).to eq(true)
    end

    it 'does not enable if the group disallows shared runners' do
      group.update!(shared_runners_enabled: false, allow_descendants_override_disabled_shared_runners: false)
      project.update!(shared_runners_enabled: false)

      post :toggle_shared_runners, params: params

      project.reload

      expect(response).to have_gitlab_http_status(:unauthorized)
      expect(project.shared_runners_enabled).to eq(false)
      expect(json_response['error'])
        .to eq('Shared runners enabled cannot be enabled because parent group does not allow it')
    end
  end
end
