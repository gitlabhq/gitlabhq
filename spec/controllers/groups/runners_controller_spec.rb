# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::RunnersController do
  let_it_be(:user)   { create(:user) }
  let_it_be(:group)  { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let!(:runner) { create(:ci_runner, :group, groups: [group]) }
  let!(:runner_project) { create(:ci_runner, :project, projects: [project]) }

  let(:params_runner_project) { { group_id: group, id: runner_project } }
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
        expect(assigns(:group_runners_limited_count)).to be(2)
      end

      it 'tracks the event' do
        get :index, params: { group_id: group }

        expect_snowplow_event(category: described_class.name, action: 'index', user: user, namespace: group)
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

      it 'renders show with 200 status code project runner' do
        get :show, params: { group_id: group, id: runner_project }

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

      it 'renders a 404 project runner' do
        get :show, params: { group_id: group, id: runner_project }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#edit' do
    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'renders show with 200 status code' do
        get :edit, params: { group_id: group, id: runner }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
      end

      it 'renders show with 200 status code project runner' do
        get :edit, params: { group_id: group, id: runner_project }

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
        get :edit, params: { group_id: group, id: runner_project }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#update' do
    context 'when user is an owner' do
      before do
        group.add_owner(user)
      end

      it 'updates the runner, ticks the queue, and redirects' do
        new_desc = runner.description.swapcase

        expect do
          post :update, params: params.merge(runner: { description: new_desc } )
        end.to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:found)
        expect(runner.reload.description).to eq(new_desc)
      end

      it 'updates the project runner, ticks the queue, and redirects project runner' do
        new_desc = runner_project.description.swapcase

        expect do
          post :update, params: params_runner_project.merge(runner: { description: new_desc } )
        end.to change { runner_project.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:found)
        expect(runner_project.reload.description).to eq(new_desc)
      end
    end

    context 'when user is not an owner' do
      before do
        group.add_maintainer(user)
      end

      it 'rejects the update and responds 404' do
        old_desc = runner.description

        expect do
          post :update, params: params.merge(runner: { description: old_desc.swapcase } )
        end.not_to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(runner.reload.description).to eq(old_desc)
      end

      it 'rejects the update and responds 404 project runner' do
        old_desc = runner_project.description

        expect do
          post :update, params: params_runner_project.merge(runner: { description: old_desc.swapcase } )
        end.not_to change { runner_project.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(runner_project.reload.description).to eq(old_desc)
      end
    end
  end
end
