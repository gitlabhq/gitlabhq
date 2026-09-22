# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::JobsController, feature_category: :continuous_integration do
  describe 'GET #index' do
    context 'with an authenticated admin user' do
      it 'renders the index for an admin' do
        sign_in(create(:admin))

        get :index

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'without admin access' do
      it 'returns `not_found`' do
        sign_in(create(:user))

        get :index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
