# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::SubscriptionsController do
  let_it_be(:installation) { create(:jira_connect_installation) }

  describe '#index' do
    before do
      get :index, params: { jwt: jwt }
    end

    context 'without JWT' do
      let(:jwt) { nil }

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with valid JWT' do
      let(:qsh) { Atlassian::Jwt.create_query_string_hash('https://gitlab.test/subscriptions', 'GET', 'https://gitlab.test') }
      let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'removes X-Frame-Options to allow rendering in iframe' do
        expect(response.headers['X-Frame-Options']).to be_nil
      end
    end
  end

  describe '#create' do
    let(:group) { create(:group) }
    let(:user) { create(:user) }
    let(:current_user) { user }

    before do
      group.add_maintainer(user)
    end

    subject { post :create, params: { jwt: jwt, namespace_path: group.path, format: :json } }

    context 'without JWT' do
      let(:jwt) { nil }

      it 'returns 403' do
        sign_in(user)

        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with valid JWT' do
      let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key }, installation.shared_secret) }

      context 'signed in to GitLab' do
        before do
          sign_in(user)
        end

        context 'dev panel integration is available' do
          it 'creates a subscription' do
            expect { subject }.to change { installation.subscriptions.count }.from(0).to(1)
          end

          it 'returns 200' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'not signed in to GitLab' do
        it 'returns 401' do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end
  end

  describe '#destroy' do
    let(:subscription) { create(:jira_connect_subscription, installation: installation) }

    before do
      delete :destroy, params: { jwt: jwt, id: subscription.id }
    end

    context 'without JWT' do
      let(:jwt) { nil }

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with valid JWT' do
      let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key }, installation.shared_secret) }

      it 'deletes the subscription' do
        expect { subscription.reload }.to raise_error ActiveRecord::RecordNotFound
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
