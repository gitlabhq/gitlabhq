# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeployKeysController, feature_category: :continuous_delivery do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  describe 'GET actions' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }

    let_it_be(:accessible_project) { create(:project, :internal, developers: user) }
    let_it_be(:inaccessible_project) { create(:project, :internal) }
    let_it_be(:project_private) { create(:project, :private) }

    let_it_be(:deploy_key_for_target_project) do
      create(:deploy_keys_project, project: project, deploy_key: create(:deploy_key))
    end

    let_it_be(:deploy_key_for_accessible_project) do
      create(:deploy_keys_project, project: accessible_project, deploy_key: create(:deploy_key))
    end

    let_it_be(:deploy_key_for_inaccessible_project) do
      create(:deploy_keys_project, project: inaccessible_project, deploy_key: create(:deploy_key))
    end

    let_it_be(:deploy_keys_project_private) do
      create(:deploy_keys_project, project: project_private, deploy_key: create(:another_deploy_key))
    end

    let_it_be(:deploy_key_public) { create(:deploy_key, public: true) }

    describe 'GET index' do
      let(:params) do
        { namespace_id: project.namespace, project_id: project }
      end

      context 'when html requested' do
        it 'redirects to project settings with the correct anchor' do
          get :index, params: params

          expect(response).to redirect_to(project_settings_repository_path(project, anchor: 'js-deploy-keys-settings'))
        end
      end

      context 'when json requested' do
        it 'returns json in a correct format' do
          get :index, params: params.merge(format: :json)

          expect(json_response.keys).to match_array(%w[enabled_keys available_project_keys public_keys])
          expect(json_response['enabled_keys'].pluck('id')).to match_array(
            [deploy_key_for_target_project.deploy_key_id]
          )
          expect(json_response['available_project_keys'].pluck('id')).to match_array(
            [deploy_key_for_accessible_project.deploy_key_id]
          )
          expect(json_response['public_keys'].pluck('id')).to match_array([deploy_key_public.id])
        end
      end
    end

    describe 'GET enabled_keys' do
      let(:params) do
        { namespace_id: project.namespace, project_id: project }
      end

      it 'returns only enabled keys' do
        get :enabled_keys, params: params.merge(format: :json)

        expect(json_response['keys'].pluck("id")).to match_array([deploy_key_for_target_project.deploy_key_id])
      end
    end

    describe 'GET available_project_keys' do
      let(:params) do
        { namespace_id: project.namespace, project_id: project }
      end

      it 'returns available project keys' do
        get :available_project_keys, params: params.merge(format: :json)

        expect(json_response['keys'].pluck("id")).to match_array([deploy_key_for_accessible_project.deploy_key_id])
      end
    end

    describe 'GET available_public_keys' do
      let(:params) do
        { namespace_id: project.namespace, project_id: project }
      end

      it 'returns available public keys' do
        get :available_public_keys, params: params.merge(format: :json)

        expect(json_response['keys'].pluck("id")).to match_array([deploy_key_public.id])
      end
    end

    describe 'GET available_public_keys with search' do
      let_it_be(:another_deploy_key_public) { create(:deploy_key, public: true, title: 'new-key') }
      let(:params) do
        { namespace_id: project.namespace, project_id: project, search: 'key', in: 'title' }
      end

      it 'returns available public keys matching the search' do
        get :available_public_keys, params: params.merge(format: :json)
        expect(json_response['keys'].pluck("id")).to match_array([another_deploy_key_public.id])
      end
    end
  end

  describe 'POST create' do
    let(:deploy_key_content) { attributes_for(:deploy_key)[:key] }

    def create_params(title = 'my-key')
      {
        namespace_id: project.namespace.path,
        project_id: project.path,
        deploy_key: {
          title: title,
          key: deploy_key_content,
          deploy_keys_projects_attributes: { '0' => { can_push: '1' } }
        }
      }
    end

    it 'creates a new deploy key for the project' do
      expect { post :create, params: create_params }.to change(project.deploy_keys, :count).by(1)

      expect(response).to redirect_to(project_settings_repository_path(project, anchor: 'js-deploy-keys-settings'))
    end

    it 'redirects to project settings with the correct anchor' do
      post :create, params: create_params

      expect(response).to redirect_to(project_settings_repository_path(project, anchor: 'js-deploy-keys-settings'))
    end

    context 'when the deploy key has an invalid title' do
      it 'shows an alert with the validations errors' do
        post :create, params: create_params(nil)

        expect(flash[:alert]).to eq("Title can't be blank")
      end
    end

    context 'when the deploy key is not supported SSH public key' do
      let(:deploy_key_content) { 'bogus ssh public key' }

      it 'shows an alert with a help link' do
        post :create, params: create_params

        expect(assigns(:key).errors.count).to be > 1
        expect(flash[:alert]).to eq('Deploy key must be a <a target="_blank" rel="noopener noreferrer" ' \
          'href="/help/user/ssh#supported-ssh-key-types">supported SSH public key.</a>')
      end
    end

    context 'when the deploy key already exists' do
      before do
        create(:deploy_key, title: 'my-key', key: deploy_key_content, projects: [project])
      end

      it 'shows an alert with the validations errors' do
        post :create, params: create_params

        expect(flash[:alert]).to eq("Fingerprint sha256 has already been taken")
      end
    end
  end

  describe '/enable/:id' do
    let(:deploy_key) { create(:deploy_key) }
    let(:project2) { create(:project) }
    let!(:deploy_keys_project_internal) do
      create(:deploy_keys_project, project: project2, deploy_key: deploy_key)
    end

    context 'with anonymous user' do
      before do
        sign_out(:user)
      end

      it 'redirects to login' do
        expect do
          put :enable, params: { id: deploy_key.id, namespace_id: project.namespace, project_id: project }
        end.not_to change { DeployKeysProject.count }

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with user with no permission' do
      before do
        sign_in(create(:user))
      end

      it 'returns 404' do
        expect do
          put :enable, params: { id: deploy_key.id, namespace_id: project.namespace, project_id: project }
        end.not_to change { DeployKeysProject.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with user with permission' do
      before do
        project2.add_maintainer(user)
      end

      it 'returns 302' do
        expect do
          put :enable, params: { id: deploy_key.id, namespace_id: project.namespace, project_id: project }
        end.to change { DeployKeysProject.count }.by(1)

        expect(DeployKeysProject.where(project_id: project.id, deploy_key_id: deploy_key.id).count).to eq(1)
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_settings_repository_path(anchor: 'js-deploy-keys-settings'))
      end

      it 'returns 404' do
        put :enable, params: { id: 0, namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with admin', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      it 'returns 302' do
        expect do
          put :enable, params: { id: deploy_key.id, namespace_id: project.namespace, project_id: project }
        end.to change { DeployKeysProject.count }.by(1)

        expect(DeployKeysProject.where(project_id: project.id, deploy_key_id: deploy_key.id).count).to eq(1)
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_settings_repository_path(anchor: 'js-deploy-keys-settings'))
      end
    end
  end

  describe '/disable/:id' do
    let(:deploy_key) { create(:deploy_key) }
    let!(:deploy_key_project) { create(:deploy_keys_project, project: project, deploy_key: deploy_key) }

    context 'with anonymous user' do
      before do
        sign_out(:user)
      end

      it 'redirects to login' do
        put :disable, params: { id: deploy_key.id, namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
        expect(DeployKey.find(deploy_key.id)).to eq(deploy_key)
      end
    end

    context 'with user with no permission' do
      before do
        sign_in(create(:user))
      end

      it 'returns 404' do
        put :disable, params: { id: deploy_key.id, namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(DeployKey.find(deploy_key.id)).to eq(deploy_key)
      end
    end

    context 'with user with permission' do
      it 'returns 302' do
        put :disable, params: { id: deploy_key.id, namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_settings_repository_path(anchor: 'js-deploy-keys-settings'))

        expect { DeployKey.find(deploy_key.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'returns 404' do
        put :disable, params: { id: 0, namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with admin', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      it 'returns 302' do
        expect do
          put :disable, params: { id: deploy_key.id, namespace_id: project.namespace, project_id: project }
        end.to change { DeployKey.count }.by(-1)

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_settings_repository_path(anchor: 'js-deploy-keys-settings'))

        expect { DeployKey.find(deploy_key.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'PUT update' do
    let(:extra_params) { {} }

    subject do
      put :update, params: extra_params.reverse_merge(
        id: deploy_key.id, namespace_id: project.namespace, project_id: project
      )
    end

    def deploy_key_params(title, can_push)
      deploy_keys_projects_attributes = { '0' => { can_push: can_push } }
      { deploy_key: { title: title, deploy_keys_projects_attributes: deploy_keys_projects_attributes } }
    end

    let(:project) { create(:project) }

    context 'public deploy key' do
      let(:deploy_key) { create(:deploy_key, public: true) }
      let!(:deploy_keys_project) do
        create(:deploy_keys_project, project: project, deploy_key: deploy_key)
      end

      context 'with project maintainer' do
        before do
          project.add_maintainer(user)
        end

        context 'public deploy key attached to project' do
          let(:extra_params) { deploy_key_params('updated title', '1') }

          it 'does not update the title of the deploy key' do
            expect { subject }.not_to change { deploy_key.reload.title }
          end

          it 'updates can_push of deploy_keys_project' do
            expect { subject }.to change { deploy_keys_project.reload.can_push }.from(false).to(true)
          end
        end
      end

      context 'with admin', :enable_admin_mode do
        before do
          sign_in(admin)
        end

        context 'public deploy key attached to project' do
          let(:extra_params) { deploy_key_params('updated title', '1') }

          it 'updates the title of the deploy key' do
            expect { subject }.to change { deploy_key.reload.title }.to('updated title')
          end

          it 'updates can_push of deploy_keys_project' do
            expect { subject }.to change { deploy_keys_project.reload.can_push }.from(false).to(true)
          end
        end

        context 'when a different deploy key id param is injected' do
          let(:extra_params) { deploy_key_params('updated title', '1') }
          let(:hacked_params) do
            extra_params.reverse_merge(id: other_deploy_key_id, namespace_id: project.namespace, project_id: project)
          end

          subject { put :update, params: hacked_params }

          context 'and that deploy key id exists' do
            let(:other_project) { create(:project) }
            let(:other_deploy_key) do
              key = create(:deploy_key)
              project.deploy_keys << key
              key
            end

            let(:other_deploy_key_id) { other_deploy_key.id }

            it 'does not update the can_push attribute' do
              expect { subject }.not_to change { deploy_key.deploy_keys_project_for(project).can_push }
            end
          end

          context 'and that deploy key id does not exist' do
            let(:other_deploy_key_id) { 9999 }

            it 'returns 404' do
              subject

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end
      end

      context 'with admin as project maintainer' do
        before do
          sign_in(admin)
          project.add_maintainer(admin)
        end

        context 'public deploy key attached to project' do
          let(:extra_params) { deploy_key_params('updated title', '1') }

          context 'admin mode disabled' do
            it 'does not update the title of the deploy key' do
              expect { subject }.not_to change { deploy_key.reload.title }
            end
          end

          context 'admin mode enabled', :enable_admin_mode do
            it 'updates the title of the deploy key' do
              expect { subject }.to change { deploy_key.reload.title }.to('updated title')
            end
          end

          it 'updates can_push of deploy_keys_project' do
            expect { subject }.to change { deploy_keys_project.reload.can_push }.from(false).to(true)
          end
        end
      end
    end

    context 'private deploy key' do
      let_it_be(:deploy_key) { create(:deploy_key) }
      let_it_be(:extra_params) { deploy_key_params('updated title', '1') }

      context 'when attached to one project' do
        let!(:deploy_keys_project) do
          create(:deploy_keys_project, project: project, deploy_key: deploy_key)
        end

        context 'with admin', :enable_admin_mode do
          before do
            sign_in(admin)
          end

          it 'updates the title of the deploy key' do
            expect { subject }.to change { deploy_key.reload.title }.to('updated title')
          end

          it 'updates can_push of deploy_keys_project' do
            expect { subject }.to change { deploy_keys_project.reload.can_push }.from(false).to(true)
          end
        end

        context 'with project maintainer' do
          before do
            project.add_maintainer(user)
          end

          it 'updates the title of the deploy key' do
            expect { subject }.to change { deploy_key.reload.title }.to('updated title')
          end

          it 'updates can_push of deploy_keys_project' do
            expect { subject }.to change { deploy_keys_project.reload.can_push }.from(false).to(true)
          end
        end

        context 'with project guest' do
          before do
            project.add_guest(user)
          end

          it 'does not update the title of the deploy key' do
            expect { subject }.not_to change { deploy_key.reload.title }
          end

          it 'does not update can_push of deploy_keys_project' do
            expect { subject }.not_to change { deploy_keys_project.reload.can_push }
          end
        end
      end

      context 'when attached to multiple projects' do
        let_it_be(:another_project) { create(:project) }

        before do
          create(:deploy_keys_project, project: project, deploy_key: deploy_key)
          create(:deploy_keys_project, project: another_project, deploy_key: deploy_key)
        end

        context 'with admin', :enable_admin_mode do
          before do
            sign_in(admin)
          end

          it 'updates the title of the deploy key' do
            expect { subject }.to change { deploy_key.reload.title }.to('updated title')
          end
        end

        context 'with project maintainer' do
          before do
            project.add_maintainer(user)
          end

          it 'does not update the title of the deploy key' do
            expect { subject }.not_to change { deploy_key.reload.title }
          end
        end

        context 'with project guest' do
          before do
            project.add_guest(user)
          end

          it 'does not update the title of the deploy key' do
            expect { subject }.not_to change { deploy_key.reload.title }
          end
        end
      end
    end
  end
end
