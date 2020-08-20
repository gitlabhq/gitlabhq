# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProductAnalyticsController do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before(:all) do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
    stub_feature_flags(product_analytics: true)
  end

  describe 'GET #index' do
    it 'renders index with 200 status code' do
      get :index, params: project_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end

    context 'with an anonymous user' do
      before do
        sign_out(user)
      end

      it 'redirects to sign-in page' do
        get :index, params: project_params

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'feature flag disabled' do
      before do
        stub_feature_flags(product_analytics: false)
      end

      it 'returns not found' do
        get :index, params: project_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #test' do
    it 'renders test with 200 status code' do
      get :test, params: project_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:test)
    end
  end

  describe 'GET #setup' do
    it 'renders setup with 200 status code' do
      get :setup, params: project_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:setup)
    end
  end

  describe 'GET #graphs' do
    it 'renders graphs with 200 status code' do
      get :graphs, params: project_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:graphs)
    end

    context 'feature flag disabled' do
      before do
        stub_feature_flags(product_analytics: false)
      end

      it 'returns not found' do
        get :graphs, params: project_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  private

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
