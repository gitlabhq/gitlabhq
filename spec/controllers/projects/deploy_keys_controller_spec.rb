# frozen_string_literal: true

require 'spec_helper'

describe Projects::DeployKeysController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

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
      let(:project2) { create(:project, :internal)}
      let(:project_private) { create(:project, :private)}

      let(:deploy_key_internal) { create(:deploy_key) }
      let(:deploy_key_actual) { create(:deploy_key) }
      let!(:deploy_key_public) { create(:deploy_key, public: true) }

      let!(:deploy_keys_project_internal) do
        create(:deploy_keys_project, project: project2, deploy_key: deploy_key_internal)
      end

      let!(:deploy_keys_project_actual) do
        create(:deploy_keys_project, project: project, deploy_key: deploy_key_actual)
      end

      let!(:deploy_keys_project_private) do
        create(:deploy_keys_project, project: project_private, deploy_key: create(:another_deploy_key))
      end

      context 'when user has access to all projects where deploy keys are used' do
        before do
          project2.add_developer(user)
        end

        it 'returns json in a correct format' do
          get :index, params: params.merge(format: :json)

          expect(json_response.keys).to match_array(%w(enabled_keys available_project_keys public_keys))
          expect(json_response['enabled_keys'].count).to eq(1)
          expect(json_response['available_project_keys'].count).to eq(1)
          expect(json_response['public_keys'].count).to eq(1)
        end
      end

      context 'when user has no access to all projects where deploy keys are used' do
        it 'returns json in a correct format' do
          get :index, params: params.merge(format: :json)

          expect(json_response['available_project_keys'].count).to eq(0)
        end
      end
    end
  end

  describe 'POST create' do
    def create_params(title = 'my-key')
      {
        namespace_id: project.namespace.path,
        project_id: project.path,
        deploy_key: {
          title: title,
          key: attributes_for(:deploy_key)[:key],
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

    context 'when the deploy key is invalid' do
      it 'shows an alert with the validations errors' do
        post :create, params: create_params(nil)

        expect(flash[:alert]).to eq("Title can't be blank, Deploy keys projects deploy key title can't be blank")
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

        expect(response).to have_http_status(302)
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

        expect(response).to have_http_status(404)
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
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(namespace_project_settings_repository_path(anchor: 'js-deploy-keys-settings'))
      end

      it 'returns 404' do
        put :enable, params: { id: 0, namespace_id: project.namespace, project_id: project }

        expect(response).to have_http_status(404)
      end
    end

    context 'with admin' do
      before do
        sign_in(admin)
      end

      it 'returns 302' do
        expect do
          put :enable, params: { id: deploy_key.id, namespace_id: project.namespace, project_id: project }
        end.to change { DeployKeysProject.count }.by(1)

        expect(DeployKeysProject.where(project_id: project.id, deploy_key_id: deploy_key.id).count).to eq(1)
        expect(response).to have_http_status(302)
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

        expect(response).to have_http_status(302)
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

        expect(response).to have_http_status(404)
        expect(DeployKey.find(deploy_key.id)).to eq(deploy_key)
      end
    end

    context 'with user with permission' do
      it 'returns 302' do
        put :disable, params: { id: deploy_key.id, namespace_id: project.namespace, project_id: project }

        expect(response).to have_http_status(302)
        expect(response).to redirect_to(namespace_project_settings_repository_path(anchor: 'js-deploy-keys-settings'))

        expect { DeployKey.find(deploy_key.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'returns 404' do
        put :disable, params: { id: 0, namespace_id: project.namespace, project_id: project }

        expect(response).to have_http_status(404)
      end
    end

    context 'with admin' do
      before do
        sign_in(admin)
      end

      it 'returns 302' do
        expect do
          put :disable, params: { id: deploy_key.id, namespace_id: project.namespace, project_id: project }
        end.to change { DeployKey.count }.by(-1)

        expect(response).to have_http_status(302)
        expect(response).to redirect_to(namespace_project_settings_repository_path(anchor: 'js-deploy-keys-settings'))

        expect { DeployKey.find(deploy_key.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'PUT update' do
    let(:extra_params) { {} }

    subject do
      put :update, params: extra_params.reverse_merge(id: deploy_key.id,
                                                      namespace_id: project.namespace,
                                                      project_id: project)
    end

    def deploy_key_params(title, can_push)
      deploy_keys_projects_attributes = { '0' => { id: deploy_keys_project, can_push: can_push } }
      { deploy_key: { title: title, deploy_keys_projects_attributes: deploy_keys_projects_attributes } }
    end

    let(:deploy_key) { create(:deploy_key, public: true) }
    let(:project) { create(:project) }
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

    context 'with admin' do
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
    end

    context 'with admin as project maintainer' do
      before do
        sign_in(admin)
        project.add_maintainer(admin)
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
    end
  end
end
