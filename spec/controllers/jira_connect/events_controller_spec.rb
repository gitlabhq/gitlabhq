# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::EventsController do
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
      allow_next_instance_of(Atlassian::JiraConnect::AsymmetricJwt) do |asymmetric_jwt|
        allow(asymmetric_jwt).to receive(:valid?).and_return(true)
        allow(asymmetric_jwt).to receive(:iss_claim).and_return(client_key)
      end
    end
  end

  shared_context 'invalid JWT token' do
    before do
      allow_next_instance_of(Atlassian::JiraConnect::AsymmetricJwt) do |asymmetric_jwt|
        allow(asymmetric_jwt).to receive(:valid?).and_return(false)
      end
    end
  end

  describe '#installed' do
    let(:client_key) { '1234' }
    let(:shared_secret) { 'secret' }

    let(:params) do
      {
        clientKey: client_key,
        sharedSecret: shared_secret,
        baseUrl: 'https://test.atlassian.net'
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

    context 'when it is a version update and shared_secret is not sent' do
      let(:params) do
        {
          clientKey: client_key,
          baseUrl: 'https://test.atlassian.net'
        }
      end

      it 'returns 422' do
        subject

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end

      context 'and an installation exists' do
        let!(:installation) { create(:jira_connect_installation, client_key: client_key, shared_secret: shared_secret) }

        it 'validates the JWT token in authorization header and returns 200 without creating a new installation' do
          expect { subject }.not_to change { JiraConnectInstallation.count }
          expect(response).to have_gitlab_http_status(:ok)
        end
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
