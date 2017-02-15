require 'spec_helper'

describe Projects::RunnersController do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:runner) { create(:ci_runner) }

  let(:params) do
    {
      namespace_id: project.namespace,
      project_id: project,
      id: runner
    }
  end

  before do
    sign_in(user)
    project.add_master(user)
    project.runners << runner
  end

  describe '#update' do
    it 'updates the runner and ticks the queue' do
      old_tick = runner.ensure_runner_queue_value
      new_desc = runner.description.swapcase

      post :update, params.merge(runner: { description: new_desc } )

      runner.reload

      expect(response).to have_http_status(302)
      expect(runner.description).to eq(new_desc)
      expect(runner.ensure_runner_queue_value).not_to eq(old_tick)
    end
  end

  describe '#destroy' do
    it 'destroys the runner' do
      delete :destroy, params

      expect(response).to have_http_status(302)
      expect(Ci::Runner.find_by(id: runner.id)).to be_nil
    end
  end

  describe '#resume' do
    it 'marks the runner as active and ticks the queue' do
      old_tick = runner.ensure_runner_queue_value
      runner.update(active: false)

      post :resume, params

      runner.reload

      expect(response).to have_http_status(302)
      expect(runner.active).to eq(true)
      expect(runner.ensure_runner_queue_value).not_to eq(old_tick)
    end
  end

  describe '#pause' do
    it 'marks the runner as inactive and ticks the queue' do
      old_tick = runner.ensure_runner_queue_value
      runner.update(active: true)

      post :pause, params

      runner.reload

      expect(response).to have_http_status(302)
      expect(runner.active).to eq(false)
      expect(runner.ensure_runner_queue_value).not_to eq(old_tick)
    end
  end
end
