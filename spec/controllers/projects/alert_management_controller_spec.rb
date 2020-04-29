# frozen_string_literal: true

require 'spec_helper'

describe Projects::AlertManagementController do
  let_it_be(:project) { create(:project) }
  let_it_be(:role) { :reporter }
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
    context 'when alert_management_minimal is enabled' do
      before do
        stub_feature_flags(alert_management_minimal: true)
      end

      it 'shows the page' do
        get :details, params: { namespace_id: project.namespace, project_id: project, id: id }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when alert_management_minimal is disabled' do
      before do
        stub_feature_flags(alert_management_minimal: false)
      end

      it 'shows 404' do
        get :details, params: { namespace_id: project.namespace, project_id: project, id: id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
