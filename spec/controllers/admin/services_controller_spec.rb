# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ServicesController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #edit' do
    let(:service) do
      create(:jira_integration, :template)
    end

    it 'successfully displays the template' do
      get :edit, params: { id: service.id }

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when integration does not exists' do
      it 'redirects to the admin application integration page' do
        get :edit, params: { id: 'invalid' }

        expect(response).to redirect_to(admin_application_settings_services_path)
      end
    end

    context 'when instance integration exists' do
      before do
        create(:jira_integration, :instance)
      end

      it 'redirects to the admin application integration page' do
        get :edit, params: { id: service.id }

        expect(response).to redirect_to(admin_application_settings_services_path)
      end
    end
  end

  describe "#update" do
    let(:project) { create(:project) }
    let!(:service_template) do
      Integrations::Redmine.create!(
        project: nil,
        active: false,
        template: true,
        properties: {
          project_url: 'http://abc',
          issues_url: 'http://abc',
          new_issue_url: 'http://abc'
        }
      )
    end

    it 'calls the propagation worker when service is active' do
      expect(PropagateServiceTemplateWorker).to receive(:perform_async).with(service_template.id)

      put :update, params: { id: service_template.id, service: { active: true } }

      expect(response).to have_gitlab_http_status(:found)
    end

    it 'does not call the propagation worker when service is not active' do
      expect(PropagateServiceTemplateWorker).not_to receive(:perform_async)

      put :update, params: { id: service_template.id, service: { properties: {} } }

      expect(response).to have_gitlab_http_status(:found)
    end
  end
end
