# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::EventsController do
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

    subject do
      post :installed, params: params
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

    context 'client key already exists' do
      it 'returns 422' do
        create(:jira_connect_installation, client_key: client_key)

        subject

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when it is a version update and shared_secret is not sent' do
      let(:params) do
        {
          clientKey: client_key,
          baseUrl: 'https://test.atlassian.net'
        }
      end

      it 'validates the JWT token in authorization header and returns 200 without creating a new installation' do
        create(:jira_connect_installation, client_key: client_key, shared_secret: shared_secret)
        request.headers["Authorization"] = "Bearer #{Atlassian::Jwt.encode({ iss: client_key }, shared_secret)}"

        expect { subject }.not_to change { JiraConnectInstallation.count }
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe '#uninstalled' do
      let!(:installation) { create(:jira_connect_installation) }
      let(:qsh) { Atlassian::Jwt.create_query_string_hash('https://gitlab.test/events/uninstalled', 'POST', 'https://gitlab.test') }

      before do
        request.headers['Authorization'] = "JWT #{auth_token}"
      end

      subject { post :uninstalled }

      context 'when JWT is invalid' do
        let(:auth_token) { 'invalid_token' }

        it 'returns 403' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'does not delete the installation' do
          expect { subject }.not_to change { JiraConnectInstallation.count }
        end
      end

      context 'when JWT is valid' do
        let(:auth_token) do
          Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret)
        end

        it 'deletes the installation' do
          expect { subject }.to change { JiraConnectInstallation.count }.by(-1)
        end
      end
    end
  end
end
