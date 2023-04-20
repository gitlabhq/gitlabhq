# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::RunnersController, feature_category: :runner_fleet do
  let_it_be(:user)   { create(:user) }
  let_it_be(:group)  { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:runner) { create(:ci_runner, :group, groups: [group]) }

  let!(:project_runner) { create(:ci_runner, :project, projects: [project]) }
  let!(:instance_runner) { create(:ci_runner, :instance) }

  let(:params_runner_project) { { group_id: group, id: project_runner } }
  let(:params_runner_instance) { { group_id: group, id: instance_runner } }
  let(:params) { { group_id: group, id: runner } }

  before do
    sign_in(user)
  end

  describe '#index', :snowplow do
    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'renders show with 200 status code' do
        get :index, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
      end

      it 'tracks the event' do
        get :index, params: { group_id: group }

        expect_snowplow_event(category: described_class.name, action: 'index', user: user, namespace: group)
      end

      it 'assigns variables' do
        get :index, params: { group_id: group }

        expect(assigns(:group_new_runner_path)).to eq(new_group_runner_path(group))
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        get :index, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not track the event' do
        get :index, params: { group_id: group }

        expect_no_snowplow_event
      end
    end
  end

  describe '#new' do
    context 'when create_runner_workflow_for_namespace is enabled' do
      before do
        stub_feature_flags(create_runner_workflow_for_namespace: [group])
      end

      context 'when user is owner' do
        before do
          group.add_owner(user)
        end

        it 'renders new with 200 status code' do
          get :new, params: { group_id: group }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:new)
        end
      end

      context 'when user is not owner' do
        before do
          group.add_maintainer(user)
        end

        it 'renders a 404' do
          get :new, params: { group_id: group }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when create_runner_workflow_for_namespace is disabled' do
      before do
        stub_feature_flags(create_runner_workflow_for_namespace: false)
      end

      context 'when user is owner' do
        before do
          group.add_owner(user)
        end

        it 'renders a 404' do
          get :new, params: { group_id: group }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe '#register' do
    subject(:register) { get :register, params: { group_id: group, id: new_runner } }

    context 'when create_runner_workflow_for_namespace is enabled' do
      before do
        stub_feature_flags(create_runner_workflow_for_namespace: [group])
      end

      context 'when user is owner' do
        before do
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
        before do
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

    context 'when create_runner_workflow_for_namespace is disabled' do
      let_it_be(:new_runner) { create(:ci_runner, :group, groups: [group], registration_type: :authenticated_user) }

      before do
        stub_feature_flags(create_runner_workflow_for_namespace: false)
      end

      context 'when user is owner' do
        before do
          group.add_owner(user)
        end

        it 'returns :not_found' do
          register

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe '#show' do
    context 'when user is owner' do
      before do
        group.add_owner(user)
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

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
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
      before do
        group.add_owner(user)
      end

      it 'renders edit with 200 status code' do
        get :edit, params: { group_id: group, id: runner }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
      end

      it 'renders a 404 instance runner' do
        get :edit, params: { group_id: group, id: instance_runner }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders edit with 200 status code project runner' do
        get :edit, params: { group_id: group, id: project_runner }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        get :edit, params: { group_id: group, id: runner }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders a 404 project runner' do
        get :edit, params: { group_id: group, id: project_runner }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#update' do
    let!(:runner) { create(:ci_runner, :group, groups: [group]) }

    context 'when user is an owner' do
      before do
        group.add_owner(user)
      end

      it 'updates the runner, ticks the queue, and redirects' do
        new_desc = runner.description.swapcase

        expect do
          post :update, params: params.merge(runner: { description: new_desc })
        end.to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:found)
        expect(runner.reload.description).to eq(new_desc)
      end

      it 'does not update the instance runner' do
        new_desc = instance_runner.description.swapcase

        expect do
          post :update, params: params_runner_instance.merge(runner: { description: new_desc })
        end.to not_change { instance_runner.ensure_runner_queue_value }
           .and not_change { instance_runner.description }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'updates the project runner, ticks the queue, and redirects project runner' do
        new_desc = project_runner.description.swapcase

        expect do
          post :update, params: params_runner_project.merge(runner: { description: new_desc })
        end.to change { project_runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:found)
        expect(project_runner.reload.description).to eq(new_desc)
      end
    end

    context 'when user is not an owner' do
      before do
        group.add_maintainer(user)
      end

      it 'rejects the update and responds 404' do
        old_desc = runner.description

        expect do
          post :update, params: params.merge(runner: { description: old_desc.swapcase })
        end.not_to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(runner.reload.description).to eq(old_desc)
      end

      it 'rejects the update and responds 404 instance runner' do
        old_desc = instance_runner.description

        expect do
          post :update, params: params_runner_instance.merge(runner: { description: old_desc.swapcase })
        end.not_to change { instance_runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(instance_runner.reload.description).to eq(old_desc)
      end

      it 'rejects the update and responds 404 project runner' do
        old_desc = project_runner.description

        expect do
          post :update, params: params_runner_project.merge(runner: { description: old_desc.swapcase })
        end.not_to change { project_runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(project_runner.reload.description).to eq(old_desc)
      end
    end
  end
end
