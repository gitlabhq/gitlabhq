require 'spec_helper'

describe Projects::PipelinesSettingsController do
  set(:user) { create(:user) }
  set(:project_auto_devops) { create(:project_auto_devops) }
  let(:project) { project_auto_devops.project }

  before do
    project.add_master(user)

    sign_in(user)
  end

  describe 'PATCH update' do
    subject do
      patch :update,
        namespace_id: project.namespace.to_param,
        project_id: project,
        project: { auto_devops_attributes: params,
                   run_auto_devops_pipeline_implicit: 'false',
                   run_auto_devops_pipeline_explicit: auto_devops_pipeline }
    end

    context 'when updating the auto_devops settings' do
      let(:params) { { enabled: '', domain: 'mepmep.md' } }
      let(:auto_devops_pipeline) { 'false' }

      it 'redirects to the settings page' do
        subject

        expect(response).to have_gitlab_http_status(302)
        expect(flash[:notice]).to eq("Pipelines settings for '#{project.name}' were successfully updated.")
      end

      context 'following the instance default' do
        let(:params) { { enabled: '' } }

        it 'allows enabled to be set to nil' do
          subject
          project_auto_devops.reload

          expect(project_auto_devops.enabled).to be_nil
        end
      end

      context 'when run_auto_devops_pipeline is true' do
        let(:auto_devops_pipeline) { 'true' }

        it 'queues a CreatePipelineWorker' do
          expect(CreatePipelineWorker).to receive(:perform_async).with(project.id, user.id, project.default_branch, :web, any_args)

          subject
        end
      end

      context 'when run_auto_devops_pipeline is not true' do
        let(:auto_devops_pipeline) { 'false' }

        it 'does not queue a CreatePipelineWorker' do
          expect(CreatePipelineWorker).not_to receive(:perform_async).with(project.id, user.id, :web, any_args)

          subject
        end
      end
    end
  end
end
