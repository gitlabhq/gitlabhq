# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DependencyProxyAuthController, feature_category: :container_registry do
  include DependencyProxyHelpers

  describe 'GET #authenticate' do
    subject { get :authenticate }

    context 'without JWT' do
      it 'returns unauthorized with oauth realm', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(response.headers['WWW-Authenticate']).to eq DependencyProxy::Registry.authenticate_header
      end
    end

    context 'with JWT' do
      let(:jwt) { build_jwt(user) }
      let(:token_header) { "Bearer #{jwt.encoded}" }

      before do
        request.headers['HTTP_AUTHORIZATION'] = token_header
      end

      context 'with valid JWT' do
        context 'user' do
          let_it_be(:user) { create(:user) }

          it { is_expected.to have_gitlab_http_status(:success) }
        end

        context 'group bot user' do
          let_it_be(:bot_user) { create(:user, :project_bot) }
          let_it_be(:user) { create(:personal_access_token, user: bot_user) }

          it { is_expected.to have_gitlab_http_status(:success) }
        end

        context 'service account user' do
          let_it_be(:service_account_user) { create(:user, :service_account) }
          let_it_be(:user) { create(:personal_access_token, user: service_account_user) }

          it { is_expected.to have_gitlab_http_status(:success) }
        end

        context 'deploy token' do
          let_it_be(:user) { create(:deploy_token) }

          it { is_expected.to have_gitlab_http_status(:success) }
        end
      end

      context 'with invalid JWT' do
        context 'bad user' do
          let(:jwt) { build_jwt(double('bad_user', id: 999)) }

          it { is_expected.to have_gitlab_http_status(:unauthorized) }
        end

        context 'token with no user id' do
          let(:token_header) { "Bearer #{build_jwt.encoded}" }

          before do
            request.headers['HTTP_AUTHORIZATION'] = token_header
          end

          it { is_expected.to have_gitlab_http_status(:unauthorized) }
        end

        context 'expired token' do
          let_it_be(:user) { create(:user) }

          let(:jwt) { build_jwt(user, expire_time: Time.zone.now - 1.hour) }

          it { is_expected.to have_gitlab_http_status(:unauthorized) }
        end

        context 'group bot user from an expired token' do
          let_it_be(:user) { create(:user, :project_bot) }

          let(:jwt) { build_jwt(user, expire_time: Time.zone.now - 1.hour) }

          it { is_expected.to have_gitlab_http_status(:unauthorized) }
        end

        context 'service account user from an expired token' do
          let_it_be(:user) { create(:user, :service_account) }

          let(:jwt) { build_jwt(user, expire_time: Time.zone.now - 1.hour) }

          it { is_expected.to have_gitlab_http_status(:unauthorized) }
        end

        context 'expired deploy token' do
          let_it_be(:user) { create(:deploy_token, :expired) }

          it { is_expected.to have_gitlab_http_status(:unauthorized) }
        end

        context 'revoked deploy token' do
          let_it_be(:user) { create(:deploy_token, :revoked) }

          it { is_expected.to have_gitlab_http_status(:unauthorized) }
        end
      end
    end
  end
end
