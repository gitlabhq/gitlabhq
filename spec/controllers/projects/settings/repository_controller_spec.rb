require 'spec_helper'

describe Projects::Settings::RepositoryController, :clean_gitlab_redis_shared_state do
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

    context 'with no deploy token attributes present' do
      it 'should build an empty instance of DeployToken' do
        get :show, namespace_id: project.namespace, project_id: project

        deploy_token = assigns(:deploy_token)
        expect(deploy_token).to be_an_instance_of(DeployToken)
        expect(deploy_token.name).to be_nil
        expect(deploy_token.expires_at).to be_nil
        expect(deploy_token.scopes).to eq([])
      end
    end

    context 'with deploy token attributes present' do
      let(:deploy_token_key) { "gitlab:deploy_token:#{project.id}:#{user.id}:attributes" }

      let(:deploy_token_attributes) do
        {
          name: 'test-token',
          expires_at: Date.today + 1.month
        }
      end

      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(deploy_token_key, deploy_token_attributes.to_json)
        end

        get :show, namespace_id: project.namespace, project_id: project
      end

      it 'should build an instance of DeployToken' do
        deploy_token = assigns(:deploy_token)
        expect(deploy_token).to be_an_instance_of(DeployToken)
        expect(deploy_token.name).to eq(deploy_token_attributes[:name])
        expect(deploy_token.expires_at.to_date).to eq(deploy_token_attributes[:expires_at].to_date)
      end
    end
  end
end
