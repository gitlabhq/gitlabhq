# frozen_string_literal: true

require 'spec_helper'

describe Groups::RunnersController do
  let(:user)   { create(:user) }
  let(:group)  { create(:group) }
  let(:runner) { create(:ci_runner, :group, groups: [group]) }
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

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:show)
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        get :show, params: { group_id: group, id: runner }

        expect(response).to have_gitlab_http_status(404)
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

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:edit)
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        get :edit, params: { group_id: group, id: runner }

        expect(response).to have_gitlab_http_status(404)
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

        expect(response).to have_gitlab_http_status(302)
        expect(runner.reload.description).to eq(new_desc)
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

        expect(response).to have_gitlab_http_status(404)
        expect(runner.reload.description).to eq(old_desc)
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

        expect(response).to have_gitlab_http_status(302)
        expect(Ci::Runner.find_by(id: runner.id)).to be_nil
      end
    end

    context 'when user is not an owner' do
      before do
        group.add_maintainer(user)
      end

      it 'responds 404 and does not destroy the runner' do
        delete :destroy, params: params

        expect(response).to have_gitlab_http_status(404)
        expect(Ci::Runner.find_by(id: runner.id)).to be_present
      end
    end
  end

  describe '#resume' do
    context 'when user is an owner' do
      before do
        group.add_owner(user)
      end

      it 'marks the runner as active, ticks the queue, and redirects' do
        runner.update(active: false)

        expect do
          post :resume, params: params
        end.to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(302)
        expect(runner.reload.active).to eq(true)
      end
    end

    context 'when user is not an owner' do
      before do
        group.add_maintainer(user)
      end

      it 'responds 404 and does not activate the runner' do
        runner.update(active: false)

        expect do
          post :resume, params: params
        end.not_to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(404)
        expect(runner.reload.active).to eq(false)
      end
    end
  end

  describe '#pause' do
    context 'when user is an owner' do
      before do
        group.add_owner(user)
      end

      it 'marks the runner as inactive, ticks the queue, and redirects' do
        runner.update(active: true)

        expect do
          post :pause, params: params
        end.to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(302)
        expect(runner.reload.active).to eq(false)
      end
    end

    context 'when user is not an owner' do
      before do
        group.add_maintainer(user)
      end

      it 'responds 404 and does not update the runner or queue' do
        runner.update(active: true)

        expect do
          post :pause, params: params
        end.not_to change { runner.ensure_runner_queue_value }

        expect(response).to have_gitlab_http_status(404)
        expect(runner.reload.active).to eq(true)
      end
    end
  end
end
