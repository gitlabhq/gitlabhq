# frozen_string_literal: true

require 'spec_helper'

describe Admin::ServicesController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #edit' do
    let!(:project) { create(:project) }

    Service.available_services_names.each do |service_name|
      context "#{service_name}" do
        let!(:service) do
          service_instance = "#{service_name}_service".camelize.constantize
          service_instance.where(instance: true).first_or_create
        end

        it 'successfully displays the service' do
          get :edit, params: { id: service.id }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe "#update" do
    let(:project) { create(:project) }
    let!(:service) do
      RedmineService.create(
        project: project,
        active: false,
        instance: true,
        properties: {
          project_url: 'http://abc',
          issues_url: 'http://abc',
          new_issue_url: 'http://abc'
        }
      )
    end

    it 'calls the propagation worker when service is active' do
      expect(PropagateInstanceLevelServiceWorker).to receive(:perform_async).with(service.id)

      put :update, params: { id: service.id, service: { active: true } }

      expect(response).to have_gitlab_http_status(:found)
    end

    it 'does not call the propagation worker when service is not active' do
      expect(PropagateInstanceLevelServiceWorker).not_to receive(:perform_async)

      put :update, params: { id: service.id, service: { properties: {} } }

      expect(response).to have_gitlab_http_status(:found)
    end
  end
end
