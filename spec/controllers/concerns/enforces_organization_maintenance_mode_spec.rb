# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnforcesOrganizationMaintenanceMode, feature_category: :organization do
  controller(ApplicationController) do
    include EnforcesOrganizationMaintenanceMode

    skip_before_action :authenticate_user!
    before_action :enforce_organization_maintenance_mode

    def index
      head :ok
    end

    def create
      render json: {}
    end
  end

  let(:maintenance_mode_message) do
    'This organization is temporarily unavailable due to maintenance.'
  end

  let(:indefinite_maintenance_mode_message) do
    'This organization is unavailable.'
  end

  before do
    routes.draw do
      get 'index' => 'anonymous#index'
      post 'create' => 'anonymous#create'
    end
  end

  context 'with the organization read-only enforcement feature flag enabled' do
    before do
      stub_feature_flags(organization_read_only_enforcement: true)
    end

    context 'when the current organization is in maintenance mode for a time-bounded reason' do
      let(:organization) { create(:organization) }

      before do
        organization.start_read_only(read_only_reason: 'migration')
        organization.confirm_read_only
        stub_current_organization(organization.reload)
      end

      it 'blocks JSON write requests with 503 and a Retry-After header', :aggregate_failures do
        post :create, format: :json

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(json_response['message']).to eq(maintenance_mode_message)
        expect(response.headers['Retry-After']).to eq('60')
      end

      it 'blocks JSON read requests with 503 and a Retry-After header', :aggregate_failures do
        get :index, format: :json

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(json_response['message']).to eq(maintenance_mode_message)
        expect(response.headers['Retry-After']).to eq('60')
      end

      it 'blocks HTML write requests with a 503 error page', :aggregate_failures do
        post :create, format: :html

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(response.headers['Retry-After']).to eq('60')
      end

      it 'blocks HTML read requests with a 503 error page', :aggregate_failures do
        get :index, format: :html

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(response.headers['Retry-After']).to eq('60')
      end
    end

    context 'when the current organization is in maintenance mode for an indefinite reason' do
      let(:organization) { create(:organization) }

      before do
        organization.start_read_only(read_only_reason: 'legal')
        organization.confirm_read_only
        stub_current_organization(organization.reload)
      end

      it 'blocks JSON write requests with 403 and no Retry-After header', :aggregate_failures do
        post :create, format: :json

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq(indefinite_maintenance_mode_message)
        expect(response.headers['Retry-After']).to be_nil
      end

      it 'blocks JSON read requests with 403 and no Retry-After header', :aggregate_failures do
        get :index, format: :json

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq(indefinite_maintenance_mode_message)
        expect(response.headers['Retry-After']).to be_nil
      end

      it 'blocks HTML write requests with a 403 error page carrying the maintenance message', :aggregate_failures do
        expect(controller).to receive(:access_denied!).with(indefinite_maintenance_mode_message).and_call_original

        post :create, format: :html

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(response.headers['Retry-After']).to be_nil
      end

      it 'blocks HTML read requests with a 403 error page carrying the maintenance message', :aggregate_failures do
        expect(controller).to receive(:access_denied!).with(indefinite_maintenance_mode_message).and_call_original

        get :index, format: :html

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(response.headers['Retry-After']).to be_nil
      end
    end

    context 'when the current organization is active' do
      let_it_be(:organization) { create(:organization) }

      before do
        stub_current_organization(organization)
      end

      it 'allows write requests' do
        post :create, format: :json

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'allows read requests' do
        get :index

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when there is no current organization' do
      before do
        stub_current_organization(nil)
      end

      it 'allows write requests' do
        post :create, format: :json

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'allows read requests' do
        get :index

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  context 'with the organization read-only enforcement feature flag disabled' do
    let(:organization) { create(:organization) }

    before do
      stub_feature_flags(organization_read_only_enforcement: false)
      organization.start_read_only(read_only_reason: 'migration')
      organization.confirm_read_only
      stub_current_organization(organization.reload)
    end

    it 'allows write requests' do
      post :create, format: :json

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'allows read requests' do
      get :index

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
