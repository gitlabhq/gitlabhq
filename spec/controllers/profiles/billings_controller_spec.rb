require 'spec_helper'

describe Profiles::BillingsController do
  let(:user) { create(:user) }

  describe 'GET #index' do
    before do
      stub_application_setting(check_namespace_plan: true)
      allow(Gitlab).to receive(:com?) { true }
    end

    it 'renders index with 200 status code' do
      allow_any_instance_of(FetchSubscriptionPlansService).to receive(:execute)
      sign_in(user)

      get :index

      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template(:index)
    end

    it 'fetch subscription plans data from customers.gitlab.com' do
      data = double
      expect_any_instance_of(FetchSubscriptionPlansService).to receive(:execute).and_return(data)
      sign_in(user)

      get :index

      expect(assigns(:plans_data)).to eq(data)
    end
  end
end
