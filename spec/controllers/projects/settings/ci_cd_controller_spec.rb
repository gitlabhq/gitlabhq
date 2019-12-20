# frozen_string_literal: true

require('spec_helper')

describe Projects::Settings::CiCdController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project_auto_devops) { create(:project_auto_devops) }
  let(:project) { project_auto_devops.project }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET show' do
    it 'renders show with 200 status code' do
      get :show, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template(:show)
    end

    context 'with group runners' do
      let(:parent_group) { create(:group) }
      let(:group) { create(:group, parent: parent_group) }
      let(:group_runner) { create(:ci_runner, :group, groups: [group]) }
      let(:other_project) { create(:project, group: group) }
      let!(:project_runner) { create(:ci_runner, :project, projects: [other_project]) }
      let!(:shared_runner) { create(:ci_runner, :instance) }

      it 'sets assignable project runners only' do
        group.add_maintainer(user)

        get :show, params: { namespace_id: project.namespace, project_id: project }

        expect(assigns(:assignable_runners)).to contain_exactly(project_runner)
      end
    end
  end

  describe '#reset_cache' do
    before do
      sign_in(user)

      project.add_maintainer(user)

      allow(ResetProjectCacheService).to receive_message_chain(:new, :execute).and_return(true)
    end

    subject { post :reset_cache, params: { namespace_id: project.namespace, project_id: project }, format: :json }

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

  describe 'PUT #reset_registration_token' do
    subject { put :reset_registration_token, params: { namespace_id: project.namespace, project_id: project } }

    it 'resets runner registration token' do
      expect { subject }.to change { project.reload.runners_token }
      expect(flash[:toast]).to eq('New runners registration token has been generated!')
    end

    it 'redirects the user to admin runners page' do
      subject

      expect(response).to redirect_to(namespace_project_settings_ci_cd_path)
    end
  end

  describe 'PATCH update' do
    let(:params) { { ci_config_path: '' } }

    subject do
      patch :update,
            params: {
              namespace_id: project.namespace.to_param,
              project_id: project,
              project: params
            }
    end

    it 'redirects to the settings page' do
      subject

      expect(response).to have_gitlab_http_status(302)
      expect(flash[:toast]).to eq("Pipelines settings for '#{project.name}' were successfully updated.")
    end

    context 'when updating the auto_devops settings' do
      let(:params) { { auto_devops_attributes: { enabled: '' } } }

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
          expect_next_instance_of(Projects::UpdateService) do |instance|
            expect(instance).to receive(:run_auto_devops_pipeline?).and_return(true)
          end
        end

        context 'when the project repository is empty' do
          it 'sets a notice flash' do
            expect(subject).to set_flash[:notice]
          end

          it 'does not queue a CreatePipelineWorker' do
            expect(CreatePipelineWorker).not_to receive(:perform_async).with(project.id, user.id, project.default_branch, :web, any_args)

            subject
          end
        end

        context 'when the project repository is not empty' do
          let(:project) { create(:project, :repository) }

          it 'displays a toast message' do
            allow(CreatePipelineWorker).to receive(:perform_async).with(project.id, user.id, project.default_branch, :web, any_args)

            expect(subject).to set_flash[:toast]
          end

          it 'queues a CreatePipelineWorker' do
            expect(CreatePipelineWorker).to receive(:perform_async).with(project.id, user.id, project.default_branch, :web, any_args)

            subject
          end
        end
      end

      context 'when run_auto_devops_pipeline is not true' do
        before do
          expect_next_instance_of(Projects::UpdateService) do |instance|
            expect(instance).to receive(:run_auto_devops_pipeline?).and_return(false)
          end
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

      context 'when build_timeout_human_readable is invalid' do
        let(:params) { { build_timeout_human_readable: '5m' } }

        it 'set specified timeout' do
          expect(subject).to set_flash[:alert]
          expect(response).to redirect_to(namespace_project_settings_ci_cd_path)
        end
      end

      context 'when default_git_depth is not specified' do
        let(:params) { { ci_cd_settings_attributes: { default_git_depth: 10 } } }

        before do
          project.ci_cd_settings.update!(default_git_depth: nil)
        end

        it 'set specified git depth' do
          subject

          project.reload
          expect(project.ci_default_git_depth).to eq(10)
        end
      end

      context 'when max_artifacts_size is specified' do
        let(:params) { { max_artifacts_size: 10 } }

        context 'and user is not an admin' do
          it 'does not set max_artifacts_size' do
            subject

            project.reload
            expect(project.max_artifacts_size).to be_nil
          end
        end

        context 'and user is an admin' do
          let(:user) { create(:admin)  }

          it 'sets max_artifacts_size' do
            subject

            project.reload
            expect(project.max_artifacts_size).to eq(10)
          end
        end
      end
    end
  end
end
