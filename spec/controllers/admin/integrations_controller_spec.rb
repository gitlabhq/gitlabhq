# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::IntegrationsController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe '#edit' do
    Integration.available_integration_names.each do |integration_name|
      context "#{integration_name}" do
        it 'successfully displays the template' do
          get :edit, params: { id: integration_name }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:edit)
        end
      end
    end

    context 'when GitLab.com' do
      before do
        allow(::Gitlab).to receive(:com?) { true }
      end

      it 'returns 404' do
        get :edit, params: { id: Integration.available_integration_names.sample }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#update' do
    include JiraServiceHelper

    let(:integration) { create(:jira_integration, :instance) }

    before do
      stub_jira_integration_test
      allow(PropagateIntegrationWorker).to receive(:perform_async)

      put :update, params: { id: integration.class.to_param, service: { url: url } }
    end

    context 'valid params' do
      let(:url) { 'https://jira.gitlab-example.com' }

      it 'updates the integration' do
        expect(response).to have_gitlab_http_status(:found)
        expect(integration.reload.url).to eq(url)
      end

      it 'calls to PropagateIntegrationWorker' do
        expect(PropagateIntegrationWorker).to have_received(:perform_async).with(integration.id)
      end
    end

    context 'invalid params' do
      let(:url) { 'invalid' }

      it 'does not update the integration' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
        expect(integration.reload.url).not_to eq(url)
      end

      it 'does not call to PropagateIntegrationWorker' do
        expect(PropagateIntegrationWorker).not_to have_received(:perform_async)
      end
    end
  end

  describe '#reset' do
    let_it_be(:integration) { create(:jira_integration, :instance) }
    let_it_be(:inheriting_integration) { create(:jira_integration, inherit_from_id: integration.id) }

    subject do
      post :reset, params: { id: integration.class.to_param }
    end

    it 'returns 200 OK', :aggregate_failures do
      subject

      expected_json = {}.to_json

      expect(flash[:notice]).to eq('This integration, and inheriting projects were reset.')
      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to eq(expected_json)
    end

    it 'deletes the integration and all inheriting integrations' do
      expect { subject }.to change { Integrations::Jira.for_instance.count }.by(-1)
        .and change { Integrations::Jira.inherit_from_id(integration.id).count }.by(-1)
    end
  end
end
