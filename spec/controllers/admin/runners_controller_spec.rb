require 'spec_helper'

describe Admin::RunnersController do
  let(:runner) { create(:ci_runner) }

  before do
    sign_in(create(:admin))
  end

  describe '#index' do
    it 'lists all runners' do
      get :index

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe '#show' do
    it 'shows a particular runner' do
      get :show, id: runner.id

      expect(response).to have_gitlab_http_status(200)
    end

    it 'shows 404 for unknown runner' do
      get :show, id: 0

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe '#update' do
    it 'updates the runner and ticks the queue' do
      new_desc = runner.description.swapcase

      expect do
        post :update, id: runner.id, runner: { description: new_desc }
      end.to change { runner.ensure_runner_queue_value }

      runner.reload

      expect(response).to have_gitlab_http_status(302)
      expect(runner.description).to eq(new_desc)
    end
  end

  describe '#destroy' do
    it 'destroys the runner' do
      delete :destroy, id: runner.id

      expect(response).to have_gitlab_http_status(302)
      expect(Ci::Runner.find_by(id: runner.id)).to be_nil
    end
  end

  describe '#resume' do
    it 'marks the runner as active and ticks the queue' do
      runner.update(active: false)

      expect do
        post :resume, id: runner.id
      end.to change { runner.ensure_runner_queue_value }

      runner.reload

      expect(response).to have_gitlab_http_status(302)
      expect(runner.active).to eq(true)
    end
  end

  describe '#pause' do
    it 'marks the runner as inactive and ticks the queue' do
      runner.update(active: true)

      expect do
        post :pause, id: runner.id
      end.to change { runner.ensure_runner_queue_value }

      runner.reload

      expect(response).to have_gitlab_http_status(302)
      expect(runner.active).to eq(false)
    end
  end
end
