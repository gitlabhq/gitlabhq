# frozen_string_literal: true

require 'spec_helper'

describe Admin::IntegrationsController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe '#edit' do
    context 'when instance_level_integrations not enabled' do
      it 'returns not_found' do
        stub_feature_flags(instance_level_integrations: false)

        get :edit, params: { id: Service.available_services_names.sample }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    Service.available_services_names.each do |integration_name|
      context "#{integration_name}" do
        it 'successfully displays the template' do
          get :edit, params: { id: integration_name }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe '#update' do
    let(:integration) { create(:jira_service, :instance) }

    before do
      put :update, params: { id: integration.class.to_param, service: { url: url } }
    end

    context 'valid params' do
      let(:url) { 'https://jira.gitlab-example.com' }

      it 'updates the integration' do
        expect(response).to have_gitlab_http_status(:found)
        expect(integration.reload.url).to eq(url)
      end
    end

    context 'invalid params' do
      let(:url) { 'invalid' }

      it 'does not update the integration' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
        expect(integration.reload.url).not_to eq(url)
      end
    end
  end
end
