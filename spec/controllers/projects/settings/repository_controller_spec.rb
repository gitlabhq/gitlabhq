require 'spec_helper'

describe Projects::Settings::RepositoryController do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

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

    context 'with no deploy token params' do
      it 'should build an empty instance of DeployToken' do
        get :show, namespace_id: project.namespace, project_id: project

        deploy_token = assigns(:deploy_token)
        expect(deploy_token).to be_an_instance_of(DeployToken)
        expect(deploy_token.name).to be_nil
        expect(deploy_token.expires_at).to be_nil
        expect(deploy_token.scopes).to eq([])
      end
    end

    context 'when rendering an invalid deploy token' do
      let(:deploy_token_attributes) { attributes_for(:deploy_token, project_id: project.id) }

      it 'should build an instance of DeployToken' do
        get :show, namespace_id: project.namespace, project_id: project, deploy_token: deploy_token_attributes

        deploy_token = assigns(:deploy_token)
        expect(deploy_token).to be_an_instance_of(DeployToken)
        expect(deploy_token.name).to eq(deploy_token_attributes[:name])
        expect(deploy_token.expires_at.to_date).to eq(deploy_token_attributes[:expires_at].to_date)
        expect(deploy_token.scopes).to match_array(deploy_token_attributes[:scopes])
      end
    end
  end
end
