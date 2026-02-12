# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::Projects::ApplicationController, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  controller(described_class) do
    def index
      head :ok
    end
  end

  before do
    stub_feature_flags(activity_pub_project: true)
    sign_in(user)
  end

  describe '#permitted_params' do
    it 'only permits only id, namespace_id, and project_id parameters' do
      controller_instance = described_class.new
      allow(controller_instance).to receive(:params).and_return(
        ActionController::Parameters.new(
          id: project.path,
          namespace_id: project.namespace.path,
          project_id: project.path,
          extra_param: 'value',
          malicious: 'data'
        )
      )

      result = controller_instance.send(:permitted_params)

      expect(result.keys).to contain_exactly('id', 'namespace_id', 'project_id')
      expect(result['extra_param']).to be_nil
      expect(result['malicious']).to be_nil
      expect(result.permitted?).to be true
    end
  end

  describe '#project' do
    context 'when project_id is provided' do
      it 'finds the project using permitted params' do
        get :index, params: {
          namespace_id: project.namespace.path,
          project_id: project.path
        }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when id is provided' do
      it 'finds the project using permitted params' do
        get :index, params: {
          namespace_id: project.namespace.path,
          id: project.path
        }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when neither project_id nor id is provided' do
      it 'returns early without setting project' do
        get :index, params: {
          namespace_id: project.namespace.path
        }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when project does not exist' do
      it 'returns not found' do
        get :index, params: {
          namespace_id: 'nonexistent',
          project_id: 'nonexistent'
        }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
