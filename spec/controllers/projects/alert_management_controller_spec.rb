# frozen_string_literal: true

require 'spec_helper'

describe Projects::AlertManagementController do
  let_it_be(:project) { create(:project) }
  let_it_be(:role) { :developer }
  let_it_be(:user) { create(:user) }
  let_it_be(:id) { 1 }

  before do
    project.add_role(user, role)
    sign_in(user)
  end

  describe 'GET #index' do
    context 'when alert_management_minimal is enabled' do
      before do
        stub_feature_flags(alert_management_minimal: true)
      end

      it 'shows the page' do
        get :index, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when user is unauthorized' do
        let(:role) { :reporter }

        it 'shows 404' do
          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when alert_management_minimal is disabled' do
      before do
        stub_feature_flags(alert_management_minimal: false)
      end

      it 'shows 404' do
        get :index, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #details' do
    context 'when alert_management_detail is enabled' do
      before do
        stub_feature_flags(alert_management_detail: true)
      end

      it 'shows the page' do
        get :details, params: { namespace_id: project.namespace, project_id: project, id: id }

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when user is unauthorized' do
        let(:role) { :reporter }

        it 'shows 404' do
          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when alert_management_detail is disabled' do
      before do
        stub_feature_flags(alert_management_detail: false)
      end

      it 'shows 404' do
        get :details, params: { namespace_id: project.namespace, project_id: project, id: id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'set_alert_id' do
    it 'sets alert id from the route' do
      get :details, params: { namespace_id: project.namespace, project_id: project, id: id }

      expect(assigns(:alert_id)).to eq(id.to_s)
    end
  end
end
