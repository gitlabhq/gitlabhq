# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::JobsController do
  describe 'GET #index' do
    context 'with an authenticated admin user' do
      it 'paginates builds without a total count', :aggregate_failures do
        stub_const("Admin::JobsController::BUILDS_PER_PAGE", 1)

        sign_in(create(:admin))
        create_list(:ci_build, 2)

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
