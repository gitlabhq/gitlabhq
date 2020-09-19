# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::CohortsController do
  context 'as admin' do
    let(:user) { create(:admin) }

    before do
      sign_in(user)
    end

    it 'renders 200' do
      get :index

      expect(response).to have_gitlab_http_status(:success)
    end

    describe 'GET #index' do
      it_behaves_like 'tracking unique visits', :index do
        let(:target_id) { 'i_analytics_cohorts' }
      end
    end
  end

  context 'as normal user' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it 'renders a 404' do
      get :index

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
