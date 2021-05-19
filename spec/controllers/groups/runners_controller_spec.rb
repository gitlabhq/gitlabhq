# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::RunnersController do
  let(:user)   { create(:user) }
  let(:group)  { create(:group) }
  let(:runner) { create(:ci_runner, :group, groups: [group]) }
  let(:project) { create(:project, group: group) }
  let(:runner_project) { create(:ci_runner, :project, projects: [project]) }
  let(:params_runner_project) { { group_id: group, id: runner_project } }
  let(:params) { { group_id: group, id: runner } }

  before do
    sign_in(user)
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

  describe '#destroy' do
    context 'when user is an owner' do
      before do
        group.add_owner(user)
      end

      it 'destroys the runner and redirects' do
        delete :destroy, params: params

        expect(response).to have_gitlab_http_status(:found)
        expect(Ci::Runner.find_by(id: runner.id)).to be_nil
      end

      it 'destroys the project runner and redirects' do
        delete :destroy, params: params_runner_project

        expect(response).to have_gitlab_http_status(:found)
        expect(Ci::Runner.find_by(id: runner_project.id)).to be_nil
      end
    end

    context 'when user is an owner and runner in multiple projects' do
      let(:project_2) { create(:project, group: group) }
      let(:runner_project_2) { create(:ci_runner, :project, projects: [project, project_2]) }
      let(:params_runner_project_2) { { group_id: group, id: runner_project_2 } }

      before do
        group.add_owner(user)
      end

      it 'does not destroy the project runner' do
        delete :destroy, params: params_runner_project_2

        expect(response).to have_gitlab_http_status(:found)
        expect(flash[:alert]).to eq('Runner was not deleted because it is assigned to multiple projects.')
        expect(Ci::Runner.find_by(id: runner_project_2.id)).to be_present
      end
    end

    context 'when user is not an owner' do
      before do
        group.add_maintainer(user)
      end

      it 'responds 404 and does not destroy the runner' do
        delete :destroy, params: params

        expect(response).to have_gitlab_http_status(:not_found)
        expect(Ci::Runner.find_by(id: runner.id)).to be_present
      end

      it 'responds 404 and does not destroy the project runner' do
        delete :destroy, params: params_runner_project

        expect(response).to have_gitlab_http_status(:not_found)
        expect(Ci::Runner.find_by(id: runner_project.id)).to be_present
      end
    end
  end

  describe '#resume' do
    context 'when user is an owner' do
      before do
        group.add_owner(user)
      end

      it 'marks the runner as active, ticks the queue, and redirects' do
        runner.update!(active: false)

        expect do
          post :resume, params: params
        end.to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:found)
        expect(runner.reload.active).to eq(true)
      end

      it 'marks the project runner as active, ticks the queue, and redirects' do
        runner_project.update!(active: false)

        expect do
          post :resume, params: params_runner_project
        end.to change { runner_project.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:found)
        expect(runner_project.reload.active).to eq(true)
      end
    end

    context 'when user is not an owner' do
      before do
        group.add_maintainer(user)
      end

      it 'responds 404 and does not activate the runner' do
        runner.update!(active: false)

        expect do
          post :resume, params: params
        end.not_to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(runner.reload.active).to eq(false)
      end

      it 'responds 404 and does not activate the project runner' do
        runner_project.update!(active: false)

        expect do
          post :resume, params: params_runner_project
        end.not_to change { runner_project.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(runner_project.reload.active).to eq(false)
      end
    end
  end

  describe '#pause' do
    context 'when user is an owner' do
      before do
        group.add_owner(user)
      end

      it 'marks the runner as inactive, ticks the queue, and redirects' do
        runner.update!(active: true)

        expect do
          post :pause, params: params
        end.to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:found)
        expect(runner.reload.active).to eq(false)
      end

      it 'marks the project runner as inactive, ticks the queue, and redirects' do
        runner_project.update!(active: true)

        expect do
          post :pause, params: params_runner_project
        end.to change { runner_project.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:found)
        expect(runner_project.reload.active).to eq(false)
      end
    end

    context 'when user is not an owner' do
      before do
        # Disable limit checking
        allow(runner).to receive(:runner_scope).and_return(nil)

        group.add_maintainer(user)
      end

      it 'responds 404 and does not update the runner or queue' do
        runner.update!(active: true)

        expect do
          post :pause, params: params
        end.not_to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(runner.reload.active).to eq(true)
      end

      it 'responds 404 and does not update the project runner or queue' do
        runner_project.update!(active: true)

        expect do
          post :pause, params: params
        end.not_to change { runner_project.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(runner_project.reload.active).to eq(true)
      end
    end
  end
end
