require 'spec_helper'

describe Projects::DeployTokensController do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let!(:member) { project.add_master(user) }

  before do
    sign_in(user)
  end

  describe 'POST #create' do
    let(:deploy_token_params) { attributes_for(:deploy_token) }
    subject do
      post :create,
        namespace_id: project.namespace,
        project_id: project,
        deploy_token: deploy_token_params
    end

    context 'with valid params' do
      it 'should create a new DeployToken' do
        expect { subject }.to change(DeployToken, :count).by(1)
      end

      it 'should include a flash notice' do
        subject
        expect(flash[:notice]).to eq('Your new project deploy token has been created.')
      end

      it 'should redirect to project settings repository' do
        subject
        expect(response).to redirect_to project_settings_repository_path(project)
      end
    end

    context 'with invalid params' do
      let(:deploy_token_params) { attributes_for(:deploy_token, scopes: []) }

      it 'should not create a new DeployToken' do
        expect { subject }.not_to change(DeployToken, :count)
      end

      it 'should redirect to project settings repository' do
        subject
        expect(response).to redirect_to project_settings_repository_path(project)
      end
    end

    context 'when user does not have enough permissions' do
      let!(:member) { project.add_developer(user) }

      it 'responds with status 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
