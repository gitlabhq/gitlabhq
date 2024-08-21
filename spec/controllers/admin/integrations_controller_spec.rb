# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::IntegrationsController, feature_category: :integrations do
  let_it_be(:admin) { create(:admin) }

  before do
    stub_feature_flags(remove_monitor_metrics: false)
    sign_in(admin)
  end

  it_behaves_like Integrations::Actions do
    let(:integration_attributes) { { instance: true, project: nil } }

    let(:routing_params) do
      { id: integration.to_param }
    end
  end

  describe '#edit' do
    where(:integration_name) do
      Integration.available_integration_names - Integration.project_specific_integration_names
    end

    with_them do
      it 'successfully displays the template' do
        get :edit, params: { id: integration_name }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
      end
    end

    context 'when GitLab.com', :saas do
      it 'returns 404' do
        get :edit, params: { id: Integration.available_integration_names.sample }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#update' do
    include JiraIntegrationHelpers

    let(:integration) { create(:jira_integration, :instance) }

    before do
      stub_jira_integration_test
      allow(PropagateIntegrationWorker).to receive(:perform_async)

      put :update, params: { id: integration.class.to_param, service: params }
    end

    context 'with valid params' do
      let(:params) { { url: 'https://jira.gitlab-example.com', password: 'password' } }

      it 'updates the integration' do
        expect(response).to have_gitlab_http_status(:found)
        expect(integration.reload).to have_attributes(params)
      end

      it 'calls to PropagateIntegrationWorker' do
        expect(PropagateIntegrationWorker).to have_received(:perform_async).with(integration.id)
      end
    end

    context 'with invalid params' do
      let(:params) { { url: 'invalid', password: 'password' } }

      it 'does not update the integration' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
        expect(integration.reload).not_to have_attributes(params)
      end

      it 'does not call to PropagateIntegrationWorker' do
        expect(PropagateIntegrationWorker).not_to have_received(:perform_async)
      end
    end
  end

  describe '#reset' do
    let_it_be(:integration) { create(:jira_integration, :instance) }
    let_it_be(:inheriting_integration) { create(:jira_integration, inherit_from_id: integration.id) }

    subject(:post_reset) do
      post :reset, params: { id: integration.class.to_param }
    end

    it 'returns 200 OK', :aggregate_failures do
      post_reset

      expected_json = {}.to_json

      expect(flash[:notice]).to eq('This integration, and inheriting projects were reset.')
      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to eq(expected_json)
    end

    it 'deletes the integration and all inheriting integrations' do
      expect { post_reset }.to change { Integrations::Jira.for_instance.count }.by(-1)
        .and change { Integrations::Jira.inherit_from_id(integration.id).count }.by(-1)
    end

    context 'when integration does not allow manual activation' do
      let_it_be(:integration) do
        create(:gitlab_slack_application_integration, :instance,
          slack_integration: build(:slack_integration)
        )
      end

      it 'renders unprocessable_entity' do
        stub_application_setting(slack_app_enabled: true)

        post_reset

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(response.body).to eq({ message: 'Integration cannot be reset.' }.to_json)
      end
    end
  end
end
