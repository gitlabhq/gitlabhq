# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::EventsController, feature_category: :integrations do
  shared_examples 'verifies asymmetric JWT token' do
    context 'when token is valid' do
      include_context 'valid JWT token'

      it 'renders successful' do
        send_request

        expect(response).to have_gitlab_http_status(:success)
      end
    end

    context 'when token is invalid' do
      include_context 'invalid JWT token'

      it 'renders unauthorized' do
        send_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  shared_context 'valid JWT token' do
    before do
      allow_next_instance_of(Atlassian::JiraConnect::Jwt::Asymmetric) do |asymmetric_jwt|
        allow(asymmetric_jwt).to receive(:valid?).and_return(true)
        allow(asymmetric_jwt).to receive(:iss_claim).and_return(client_key)
      end
    end
  end

  shared_context 'invalid JWT token' do
    before do
      allow_next_instance_of(Atlassian::JiraConnect::Jwt::Asymmetric) do |asymmetric_jwt|
        allow(asymmetric_jwt).to receive(:valid?).and_return(false)
      end
    end
  end

  describe '#installed' do
    let_it_be(:client_key) { '1234' }
    let_it_be(:shared_secret) { 'secret' }
    let_it_be(:base_url) { 'https://test.atlassian.net' }

    let(:params) do
      {
        clientKey: client_key,
        sharedSecret: shared_secret,
        baseUrl: base_url
      }
    end

    include_context 'valid JWT token'

    subject do
      post :installed, params: params
    end

    it_behaves_like 'verifies asymmetric JWT token' do
      let(:send_request) { subject }
    end

    it 'saves the jira installation data' do
      expect { subject }.to change { JiraConnectInstallation.count }.by(1)
    end

    it 'saves the correct values' do
      subject

      installation = JiraConnectInstallation.find_by_client_key(client_key)

      expect(installation.shared_secret).to eq(shared_secret)
      expect(installation.base_url).to eq('https://test.atlassian.net')
    end

    context 'when the shared_secret param is missing' do
      let(:params) do
        {
          clientKey: client_key,
          baseUrl: base_url
        }
      end

      it 'returns 422' do
        subject

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when an installation already exists' do
      let_it_be(:installation) { create(:jira_connect_installation, base_url: base_url, client_key: client_key, shared_secret: shared_secret) }

      it 'validates the JWT token in authorization header and returns 200 without creating a new installation', :aggregate_failures do
        expect { subject }.not_to change { JiraConnectInstallation.count }
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'uses the JiraConnectInstallations::UpdateService' do
        expect_next_instance_of(JiraConnectInstallations::UpdateService, installation, anything) do |update_service|
          expect(update_service).to receive(:execute).and_call_original
        end

        subject
      end

      context 'when parameters include a new shared secret and base_url' do
        let(:shared_secret) { 'new_secret' }
        let(:base_url) { 'https://new_test.atlassian.net' }

        it 'updates the installation', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(installation.reload).to have_attributes(
            shared_secret: shared_secret,
            base_url: base_url
          )
        end
      end

      context 'when the new base_url is invalid' do
        let(:base_url) { 'invalid' }

        it 'renders 422', :aggregate_failures do
          expect { subject }.not_to change { installation.reload.base_url }
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end
    end

    shared_examples 'generates JWT validation claims' do
      specify do
        expect_next_instance_of(Atlassian::JiraConnect::Jwt::Asymmetric, anything, expected_claims) do |asymmetric_jwt|
          allow(asymmetric_jwt).to receive(:valid?).and_return(true)
        end

        subject
      end
    end

    context 'when additional_audience_url is not configured' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:jira_connect_additional_audience_url)
          .and_return(nil)
      end

      context 'when enforce_jira_base_url_https is true' do
        before do
          allow(Gitlab.config.jira_connect).to receive(:enforce_jira_base_url_https).and_return(true)
        end

        let(:expected_claims) do
          {
            aud: ['https://test.host/-/jira_connect'],
            iss: anything,
            qsh: anything
          }
        end

        it_behaves_like 'generates JWT validation claims'
      end

      context 'when enforce_jira_base_url_https is false' do
        before do
          allow(Gitlab.config.jira_connect).to receive(:enforce_jira_base_url_https).and_return(false)
        end

        let(:expected_claims) do
          {
            aud: ['http://test.host/-/jira_connect'],
            iss: anything,
            qsh: anything
          }
        end

        it_behaves_like 'generates JWT validation claims'
      end
    end

    context 'when additional_audience_url is configured' do
      context 'when enforce_jira_base_url_https is true' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:jira_connect_additional_audience_url).and_return('https://proxy.host')
          allow(Gitlab.config.jira_connect).to receive(:enforce_jira_base_url_https).and_return(true)
        end

        let(:expected_claims) do
          {
            aud: [
              'https://test.host/-/jira_connect',
              'https://proxy.host/-/jira_connect'
            ],
            iss: anything,
            qsh: anything
          }
        end

        it_behaves_like 'generates JWT validation claims'
      end

      context 'when enforce_jira_base_url_https is false' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:jira_connect_additional_audience_url).and_return('https://proxy.host')
          allow(Gitlab.config.jira_connect).to receive(:enforce_jira_base_url_https).and_return(false)
        end

        let(:expected_claims) do
          {
            aud: [
              'http://test.host/-/jira_connect',
              'https://proxy.host/-/jira_connect'
            ],
            iss: anything,
            qsh: anything
          }
        end

        it_behaves_like 'generates JWT validation claims'
      end
    end
  end

  describe '#uninstalled' do
    let_it_be(:installation) { create(:jira_connect_installation) }

    let(:client_key) { installation.client_key }
    let(:params) do
      {
        clientKey: client_key,
        baseUrl: 'https://test.atlassian.net'
      }
    end

    it_behaves_like 'verifies asymmetric JWT token' do
      let(:send_request) { post :uninstalled, params: params }
    end

    subject(:post_uninstalled) { post :uninstalled, params: params }

    context 'when JWT is invalid' do
      include_context 'invalid JWT token'

      it 'does not delete the installation' do
        expect { post_uninstalled }.not_to change { JiraConnectInstallation.count }
      end
    end

    context 'when JWT is valid' do
      include_context 'valid JWT token'

      let(:jira_base_path) { '/-/jira_connect' }
      let(:jira_event_path) { '/-/jira_connect/events/uninstalled' }

      it 'calls the DestroyService and returns ok in case of success' do
        expect_next_instance_of(JiraConnectInstallations::DestroyService, installation, jira_base_path, jira_event_path) do |destroy_service|
          expect(destroy_service).to receive(:execute).and_return(true)
        end

        post_uninstalled

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'calls the DestroyService and returns unprocessable_entity in case of failure' do
        expect_next_instance_of(JiraConnectInstallations::DestroyService, installation, jira_base_path, jira_event_path) do |destroy_service|
          expect(destroy_service).to receive(:execute).and_return(false)
        end

        post_uninstalled

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
  end
end
