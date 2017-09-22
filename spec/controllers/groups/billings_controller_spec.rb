require 'spec_helper'

describe Groups::BillingsController do
  let(:user)  { create(:user) }
  let(:group) { create(:group, :private) }

  describe 'GET index' do
    before do
      stub_application_setting(check_namespace_plan: true)
      allow(Gitlab).to receive(:dev_env_or_com?) { true }
    end

    context 'authorized' do
      before do
        group.add_owner(user)
        sign_in(user)
      end

      it 'renders index with 200 status code' do
        allow_any_instance_of(FetchSubscriptionPlansService).to receive(:execute)

        get :index, group_id: group

        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
      end

      it 'fetches subscription plans data from customers.gitlab.com' do
        data = double
        expect_any_instance_of(FetchSubscriptionPlansService).to receive(:execute).and_return(data)

        get :index, group_id: group

        expect(assigns(:plans_data)).to eq(data)
      end
    end

    context 'unauthorized' do
      it 'renders 404 when user is not an owner' do
        group.add_developer(user)
        sign_in(user)

        get :index, group_id: group.id

        expect(response).to have_http_status(404)
      end

      it 'renders 404 when it is not gitlab.com' do
        allow(Gitlab).to receive(:dev_env_or_com?) { false }
        group.add_owner(user)
        sign_in(user)

        get :index, group_id: group

        expect(response).to have_http_status(404)
      end
    end
  end
end
