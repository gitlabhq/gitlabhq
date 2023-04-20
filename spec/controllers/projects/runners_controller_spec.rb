# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RunnersController, feature_category: :runner_fleet do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:runner) { create(:ci_runner, :project, projects: [project]) }

  let(:params) do
    {
      namespace_id: project.namespace,
      project_id: project,
      id: runner
    }
  end

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe '#new' do
    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project
      }
    end

    context 'when create_runner_workflow_for_namespace is enabled' do
      before do
        stub_feature_flags(create_runner_workflow_for_namespace: [project.namespace])
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        it 'renders new with 200 status code' do
          get :new, params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:new)
        end
      end

      context 'when user is not maintainer' do
        before do
          project.add_developer(user)
        end

        it 'renders a 404' do
          get :new, params: params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when create_runner_workflow_for_namespace is disabled' do
      before do
        stub_feature_flags(create_runner_workflow_for_namespace: false)
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        it 'renders a 404' do
          get :new, params: params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe '#update' do
    it 'updates the runner and ticks the queue' do
      new_desc = runner.description.swapcase

      expect do
        post :update, params: params.merge(runner: { description: new_desc })
      end.to change { runner.ensure_runner_queue_value }

      runner.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(runner.description).to eq(new_desc)
    end
  end

  describe '#destroy' do
    it 'destroys the runner' do
      expect_next_instance_of(Ci::Runners::UnregisterRunnerService, runner, user) do |service|
        expect(service).to receive(:execute).once.and_call_original
      end

      delete :destroy, params: params

      expect(response).to have_gitlab_http_status(:found)
      expect(Ci::Runner.find_by(id: runner.id)).to be_nil
    end
  end

  describe '#resume' do
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
    it 'marks the runner as inactive and ticks the queue' do
      runner.update!(active: true)

      expect do
        post :pause, params: params
      end.to change { runner.ensure_runner_queue_value }

      runner.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(runner.active).to eq(false)
    end
  end

  describe '#toggle_shared_runners' do
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }

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
      expect(json_response['error']).to eq('Shared runners enabled cannot be enabled because parent group does not allow it')
    end
  end
end
