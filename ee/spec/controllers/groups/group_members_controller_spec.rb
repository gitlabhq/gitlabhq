require 'spec_helper'

describe Groups::GroupMembersController do
  include ExternalAuthorizationServiceHelpers

  let(:user)  { create(:user) }
  let(:group) { create(:group, :public, :access_requestable) }
  let(:membership) { create(:group_member, group: group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'with external authorization enabled' do
    before do
      enable_external_authorization_service_check
    end

    describe 'GET #index' do
      it 'is successful' do
        get :index, group_id: group

        expect(response).to have_gitlab_http_status(200)
      end
    end

    describe 'POST #create' do
      it 'is successful' do
        post :create, group_id: group, users: user, access_level: Gitlab::Access::GUEST

        expect(response).to have_gitlab_http_status(302)
      end
    end

    describe 'PUT #update' do
      it 'is successful' do
        put :update,
            group_member: { access_level: Gitlab::Access::GUEST },
            group_id: group,
            id: membership,
            format: :js

        expect(response).to have_gitlab_http_status(200)
      end
    end

    describe 'DELETE #destroy' do
      it 'is successful' do
        delete :destroy, group_id: group, id: membership

        expect(response).to have_gitlab_http_status(302)
      end
    end

    describe 'POST #destroy' do
      it 'is successful' do
        sign_in(create(:user))

        post :request_access, group_id: group

        expect(response).to have_gitlab_http_status(302)
      end
    end

    describe 'POST #approve_request_access' do
      it 'is successful' do
        access_request = create(:group_member, :access_request, group: group)
        post :approve_access_request, group_id: group, id: access_request

        expect(response).to have_gitlab_http_status(302)
      end
    end

    describe 'DELETE #leave' do
      it 'is successful' do
        group.add_owner(create(:user))

        delete :leave, group_id: group

        expect(response).to have_gitlab_http_status(302)
      end
    end

    describe 'POST #resend_invite' do
      it 'is successful' do
        post :resend_invite, group_id: group, id: membership

        expect(response).to have_gitlab_http_status(302)
      end
    end

    describe 'POST #override' do
      let(:group) { create(:group_with_ldap_group_link) }

      it 'is successful' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :override_group_member, membership) { true }

        post :override,
             group_id: group,
             id: membership,
             group_member: { override: true },
             format: :js

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end
end
