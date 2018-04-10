require 'spec_helper'

describe Groups::RunnersController do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:runner) { create(:ci_runner) }

  let(:params) do
    {
      group_id: group,
      id: runner
    }
  end

  before do
    sign_in(user)
    group.add_master(user)
    group.runners << runner
  end

  describe '#update' do
    it 'updates the runner and ticks the queue' do
      new_desc = runner.description.swapcase

      expect do
        post :update, params.merge(runner: { description: new_desc } )
      end.to change { runner.ensure_runner_queue_value }

      runner.reload

      expect(response).to have_gitlab_http_status(302)
      expect(runner.description).to eq(new_desc)
    end
  end

  describe '#destroy' do
    it 'destroys the runner' do
      delete :destroy, params

      expect(response).to have_gitlab_http_status(302)
      expect(Ci::Runner.find_by(id: runner.id)).to be_nil
    end
  end

  describe '#resume' do
    it 'marks the runner as active and ticks the queue' do
      runner.update(active: false)

      expect do
        post :resume, params
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
        post :pause, params
      end.to change { runner.ensure_runner_queue_value }

      runner.reload

      expect(response).to have_gitlab_http_status(302)
      expect(runner.active).to eq(false)
    end
  end
end
