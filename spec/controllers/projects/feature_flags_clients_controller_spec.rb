# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::FeatureFlagsClientsController do
  include Gitlab::Routing

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  describe 'POST reset_token.json' do
    subject(:reset_token) do
      post :reset_token,
        params: { namespace_id: project.namespace, project_id: project },
        format: :json
    end

    before do
      sign_in(user)
    end

    context 'when user is a project maintainer' do
      before do
        project.add_maintainer(user)
      end

      context 'and feature flags client exist' do
        it 'regenerates feature flags client token' do
          project.create_operations_feature_flags_client!
          expect { reset_token }.to change { project.reload.feature_flags_client_token }

          expect(json_response['token']).to eq(project.feature_flags_client_token)
        end
      end

      context 'but feature flags client does not exist' do
        it 'returns 404' do
          reset_token

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when user is not a project maintainer' do
      before do
        project.add_developer(user)
      end

      it 'returns 404' do
        reset_token

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
