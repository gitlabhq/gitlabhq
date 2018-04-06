require('spec_helper')

describe Projects::Settings::CiCdController do
  set(:user) { create(:user) }
  set(:project_auto_devops) { create(:project_auto_devops) }
  let(:project) { project_auto_devops.project }

  before do
    project.add_master(user)
    sign_in(user)
  end

  describe 'GET show' do
    it 'renders show with 200 status code' do
      get :show, namespace_id: project.namespace, project_id: project

      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template(:show)
    end
  end

  describe '#reset_cache' do
    before do
      sign_in(user)

      project.add_master(user)

      allow(ResetProjectCacheService).to receive_message_chain(:new, :execute).and_return(true)
    end

    subject { post :reset_cache, namespace_id: project.namespace, project_id: project, format: :json }

    it 'calls reset project cache service' do
      expect(ResetProjectCacheService).to receive_message_chain(:new, :execute)

      subject
    end

    context 'when service returns successfully' do
      it 'returns a success header' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when service does not return successfully' do
      before do
        allow(ResetProjectCacheService).to receive_message_chain(:new, :execute).and_return(false)
      end

      it 'returns an error header' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe 'PATCH update' do
    let(:params) { { ci_config_path: '' } }

    subject do
      patch :update,
            namespace_id: project.namespace.to_param,
            project_id: project,
            project: params
    end

    it 'redirects to the settings page' do
      subject

      expect(response).to have_gitlab_http_status(302)
      expect(flash[:notice]).to eq("Pipelines settings for '#{project.name}' were successfully updated.")
    end

    context 'when updating the auto_devops settings' do
      let(:params) { { auto_devops_attributes: { enabled: '', domain: 'mepmep.md' } } }

      context 'following the instance default' do
        let(:params) { { auto_devops_attributes: { enabled: '' } } }

        it 'allows enabled to be set to nil' do
          subject
          project_auto_devops.reload

          expect(project_auto_devops.enabled).to be_nil
        end
      end

      context 'when run_auto_devops_pipeline is true' do
        before do
          expect_any_instance_of(Projects::UpdateService).to receive(:run_auto_devops_pipeline?).and_return(true)
        end

        context 'when the project repository is empty' do
          it 'sets a warning flash' do
            expect(subject).to set_flash[:warning]
          end

          it 'does not queue a CreatePipelineWorker' do
            expect(CreatePipelineWorker).not_to receive(:perform_async).with(project.id, user.id, project.default_branch, :web, any_args)

            subject
          end
        end

        context 'when the project repository is not empty' do
          let(:project) { create(:project, :repository) }

          it 'sets a success flash' do
            allow(CreatePipelineWorker).to receive(:perform_async).with(project.id, user.id, project.default_branch, :web, any_args)

            expect(subject).to set_flash[:success]
          end

          it 'queues a CreatePipelineWorker' do
            expect(CreatePipelineWorker).to receive(:perform_async).with(project.id, user.id, project.default_branch, :web, any_args)

            subject
          end
        end
      end

      context 'when run_auto_devops_pipeline is not true' do
        before do
          expect_any_instance_of(Projects::UpdateService).to receive(:run_auto_devops_pipeline?).and_return(false)
        end

        it 'does not queue a CreatePipelineWorker' do
          expect(CreatePipelineWorker).not_to receive(:perform_async).with(project.id, user.id, :web, any_args)

          subject
        end
      end
    end

    context 'when updating general settings' do
      context 'when build_timeout_human_readable is not specified' do
        let(:params) { { build_timeout_human_readable: '' } }

        it 'set default timeout' do
          subject

          project.reload
          expect(project.build_timeout).to eq(3600)
        end
      end

      context 'when build_timeout_human_readable is specified' do
        let(:params) { { build_timeout_human_readable: '1h 30m' } }

        it 'set specified timeout' do
          subject

          project.reload
          expect(project.build_timeout).to eq(5400)
        end
      end
    end
  end
end
