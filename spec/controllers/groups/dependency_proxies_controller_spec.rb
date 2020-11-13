# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DependencyProxiesController do
  let(:group) { create(:group) }
  let(:user)  { create(:user) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'GET #show' do
    context 'feature enabled' do
      before do
        enable_dependency_proxy
      end

      it 'returns 200 and renders the view' do
        get :show, params: { group_id: group.to_param }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('groups/dependency_proxies/show')
      end
    end

    it 'returns 404 when feature is disabled' do
      disable_dependency_proxy

      get :show, params: { group_id: group.to_param }

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'PUT #update' do
    context 'feature enabled' do
      before do
        enable_dependency_proxy
      end

      it 'redirects back to show page' do
        put :update, params: update_params

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    it 'returns 404 when feature is disabled' do
      put :update, params: update_params

      expect(response).to have_gitlab_http_status(:not_found)
    end

    def update_params
      {
        group_id: group.to_param,
        dependency_proxy_group_setting: { enabled: true }
      }
    end
  end

  def enable_dependency_proxy
    stub_config(dependency_proxy: { enabled: true })

    group.create_dependency_proxy_setting!(enabled: true)
  end

  def disable_dependency_proxy
    group.create_dependency_proxy_setting!(enabled: false)
  end
end
