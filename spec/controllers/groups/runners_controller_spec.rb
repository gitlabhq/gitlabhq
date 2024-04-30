# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::RunnersController, feature_category: :fleet_visibility do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace_settings) do
    create(:namespace_settings, runner_registration_enabled: true, allow_runner_registration_token: true)
  end

  let_it_be(:group) { create(:group, namespace_settings: namespace_settings) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:runner) { create(:ci_runner, :group, groups: [group]) }

  let!(:project_runner) { create(:ci_runner, :project, projects: [project]) }
  let!(:instance_runner) { create(:ci_runner, :instance) }
  let(:runner_registration_enabled) { true }

  before do
    namespace_settings.update!(runner_registration_enabled: runner_registration_enabled)

    sign_in(user)
  end

  describe '#index', :snowplow do
    let(:allow_runner_registration_token) { false }

    subject(:execute_get_request) { get :index, params: { group_id: group } }

    before do
      stub_application_setting(allow_runner_registration_token: allow_runner_registration_token)
    end

    shared_examples 'can access the page' do
      it 'renders index with 200 status code' do
        execute_get_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
      end

      it 'tracks the event' do
        execute_get_request

        expect_snowplow_event(category: described_class.name, action: 'index', user: user, namespace: group)
      end
    end

    shared_examples 'cannot access the page' do
      it 'renders 404' do
        execute_get_request

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not track the event' do
        execute_get_request

        expect_no_snowplow_event
      end
    end

    context 'when the user is a maintainer' do
      before_all do
        group.add_maintainer(user)
      end

      include_examples 'can access the page'

      context 'when runner registration is allowed' do
        let(:allow_runner_registration_token) { true }

        it 'does not expose runner creation and registration variables' do
          execute_get_request

          expect(assigns(:group_runner_registration_token)).to be_nil
          expect(assigns(:group_new_runner_path)).to be_nil
        end
      end
    end

    context 'when the user is an owner' do
      before_all do
        group.add_owner(user)
      end

      include_examples 'can access the page'

      it 'does not expose runner registration variables' do
        execute_get_request

        expect(assigns(:group_runner_registration_token)).to be_nil
      end

      context 'when runner registration is allowed' do
        let(:allow_runner_registration_token) { true }

        it 'exposes runner creation and registration variables' do
          execute_get_request

          expect(assigns(:group_runner_registration_token)).not_to be_nil
          expect(assigns(:group_new_runner_path)).to eq(new_group_runner_path(group))
        end

        context 'when runner registration is disabled' do
          let(:runner_registration_enabled) { false }

          it 'does not expose runner creation and registration variables' do
            execute_get_request

            expect(assigns(:group_runner_registration_token)).to be_nil
            expect(assigns(:group_new_runner_path)).to be_nil
          end
        end
      end
    end

    context 'when user is not maintainer' do
      before_all do
        group.add_developer(user)
      end

      include_examples 'cannot access the page'
    end
  end

  describe '#new' do
    context 'when user is owner' do
      before_all do
        group.add_owner(user)
      end

      it 'renders new with 200 status code' do
        get :new, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:new)
      end
    end

    context 'when user is not owner' do
      before_all do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        get :new, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#register' do
    subject(:register) { get :register, params: { group_id: group, id: new_runner } }

    context 'when user is owner' do
      before_all do
        group.add_owner(user)
      end

      context 'when runner can be registered after creation' do
        let_it_be(:new_runner) { create(:ci_runner, :group, groups: [group], registration_type: :authenticated_user) }

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
    end

    context 'when user is not owner' do
      before_all do
        group.add_maintainer(user)
      end

      context 'when runner can be registered after creation' do
        let_it_be(:new_runner) { create(:ci_runner, :group, groups: [group], registration_type: :authenticated_user) }

        it 'returns :not_found' do
          register

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe '#show' do
    context 'when user is maintainer' do
      before_all do
        group.add_maintainer(user)
      end

      it 'renders show with 200 status code' do
        get :show, params: { group_id: group, id: runner }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end

      it 'renders show with 200 status code instance runner' do
        get :show, params: { group_id: group, id: instance_runner }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end

      it 'renders show with 200 status code project runner' do
        get :show, params: { group_id: group, id: project_runner }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end

    context 'when user is not maintainer' do
      before_all do
        group.add_developer(user)
      end

      it 'renders a 404' do
        get :show, params: { group_id: group, id: runner }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders a 404 instance runner' do
        get :show, params: { group_id: group, id: instance_runner }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders a 404 project runner' do
        get :show, params: { group_id: group, id: project_runner }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#edit' do
    context 'when user is owner' do
      before_all do
        group.add_owner(user)
      end

      it 'renders 200 for group runner' do
        get :edit, params: { group_id: group, id: runner }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
      end

      it 'renders 404 for non-existing runner' do
        get :edit, params: { group_id: group, id: non_existing_record_id }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders 404 for instance runner' do
        get :edit, params: { group_id: group, id: instance_runner }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders 200 for project runner' do
        get :edit, params: { group_id: group, id: project_runner }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
      end
    end

    context 'when user is maintainer' do
      before_all do
        group.add_maintainer(user)
      end

      it 'renders 404 for group runner' do
        get :edit, params: { group_id: group, id: runner }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders 404 for instance runner' do
        get :edit, params: { group_id: group, id: instance_runner }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders 200 for project runner' do
        get :edit, params: { group_id: group, id: project_runner }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
      end
    end

    context 'when user is not maintainer' do
      before_all do
        group.add_developer(user)
      end

      it 'renders 404 for group runner' do
        get :edit, params: { group_id: group, id: runner }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders 404 for instance runner' do
        get :edit, params: { group_id: group, id: instance_runner }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders 404 for project runner' do
        get :edit, params: { group_id: group, id: project_runner }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#update' do
    let!(:group_runner) { create(:ci_runner, :group, groups: [group]) }

    shared_examples 'updates the runner' do
      it 'updates the runner, ticks the queue, and redirects' do
        new_desc = runner.description.swapcase

        expect do
          post :update, params: { group_id: group, id: runner, runner: { description: new_desc } }
          runner.reload
        end.to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:found)
        expect(runner.reload.description).to eq(new_desc)
      end
    end

    shared_examples 'rejects the update' do
      it 'does not update the runner' do
        new_desc = runner.description.swapcase

        expect do
          post :update, params: { group_id: group, id: runner, runner: { description: new_desc } }
          runner.reload
        end.to not_change { runner.ensure_runner_queue_value }
           .and not_change { runner.description }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is owner' do
      before_all do
        group.add_owner(user)
      end

      context 'with group runner' do
        let(:runner) { group_runner }

        it_behaves_like 'updates the runner'
      end

      context 'with instance runner' do
        let(:runner) { instance_runner }

        it_behaves_like 'rejects the update'
      end

      context 'with project runner' do
        let(:runner) { project_runner }

        it_behaves_like 'updates the runner'
      end
    end

    context 'when user is maintainer' do
      before_all do
        group.add_maintainer(user)
      end

      context 'with group runner' do
        let(:runner) { group_runner }

        it_behaves_like 'rejects the update'
      end

      context 'with instance runner' do
        let(:runner) { instance_runner }

        it_behaves_like 'rejects the update'
      end

      context 'with project runner' do
        let(:runner) { project_runner }

        it_behaves_like 'updates the runner'
      end
    end

    context 'when user is not maintainer' do
      before_all do
        group.add_developer(user)
      end

      context 'with group runner' do
        let(:runner) { group_runner }

        it_behaves_like 'rejects the update'
      end

      context 'with instance runner' do
        let(:runner) { instance_runner }

        it_behaves_like 'rejects the update'
      end

      context 'with project runner' do
        let(:runner) { project_runner }

        it_behaves_like 'rejects the update'
      end
    end
  end
end
