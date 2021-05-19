# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::DevOpsReportController do
  describe 'show_adoption?' do
    it 'is always false' do
      expect(controller.show_adoption?).to be_falsey
    end
  end

  describe 'GET #show' do
    context 'as admin' do
      let(:user) { create(:admin) }

      before do
        sign_in(user)
      end

      it 'responds with success' do
        get :show

        expect(response).to have_gitlab_http_status(:success)
      end

      it_behaves_like 'tracking unique visits', :show do
        let(:target_id) { 'i_analytics_dev_ops_score' }

        let(:request_params) { { tab: 'devops-score' } }
      end
    end
  end

  context 'as normal user' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it 'responds with 404' do
      get :show

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
