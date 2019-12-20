# frozen_string_literal: true

require 'spec_helper'

describe Groups::GroupMembersController do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:membership) { create(:group_member, group: group) }

  describe 'GET index' do
    it 'renders index with 200 status code' do
      get :index, params: { group_id: group }

      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template(:index)
    end

    context 'user with owner access' do
      let!(:invited) { create_list(:group_member, 3, :invited, group: group) }

      before do
        group.add_owner(user)
        sign_in(user)
      end

      it 'assigns invited members' do
        get :index, params: { group_id: group }

        expect(assigns(:invited_members).map(&:invite_email)).to match_array(invited.map(&:invite_email))
      end

      it 'restricts search to one email' do
        get :index, params: { group_id: group, search_invited: invited.first.invite_email }

        expect(assigns(:invited_members).map(&:invite_email)).to match_array(invited.first.invite_email)
      end

      it 'paginates invited list' do
        stub_const('Groups::GroupMembersController::MEMBER_PER_PAGE_LIMIT', 2)

        get :index, params: { group_id: group, invited_members_page: 1 }

        expect(assigns(:invited_members).count).to eq(2)

        get :index, params: { group_id: group, invited_members_page: 2 }

        expect(assigns(:invited_members).count).to eq(1)
      end
    end

    context 'when user has owner access to subgroup' do
      let(:nested_group) { create(:group, parent: group) }
      let(:nested_group_user) { create(:user) }

      before do
        group.add_owner(user)
        nested_group.add_owner(nested_group_user)
        sign_in(user)
      end

      it 'lists inherited group members by default' do
        get :index, params: { group_id: nested_group }

        expect(assigns(:members).map(&:user_id)).to contain_exactly(user.id, nested_group_user.id)
      end

      it 'lists direct group members only' do
        get :index, params: { group_id: nested_group, with_inherited_permissions: 'exclude' }

        expect(assigns(:members).map(&:user_id)).to contain_exactly(nested_group_user.id)
      end

      it 'lists inherited group members only' do
        get :index, params: { group_id: nested_group, with_inherited_permissions: 'only' }

        expect(assigns(:members).map(&:user_id)).to contain_exactly(user.id)
      end
    end
  end

  describe 'POST create' do
    let(:group_user) { create(:user) }

    before do
      sign_in(user)
    end

    context 'when user does not have enough rights' do
      before do
        group.add_developer(user)
      end

      it 'returns 403' do
        post :create, params: {
                        group_id: group,
                        user_ids: group_user.id,
                        access_level: Gitlab::Access::GUEST
                      }

        expect(response).to have_gitlab_http_status(403)
        expect(group.users).not_to include group_user
      end
    end

    context 'when user has enough rights' do
      before do
        group.add_owner(user)
      end

      it 'adds user to members' do
        post :create, params: {
                        group_id: group,
                        user_ids: group_user.id,
                        access_level: Gitlab::Access::GUEST
                      }

        expect(response).to set_flash.to 'Users were successfully added.'
        expect(response).to redirect_to(group_group_members_path(group))
        expect(group.users).to include group_user
      end

      it 'adds no user to members' do
        post :create, params: {
                        group_id: group,
                        user_ids: '',
                        access_level: Gitlab::Access::GUEST
                      }

        expect(response).to set_flash.to 'No users specified.'
        expect(response).to redirect_to(group_group_members_path(group))
        expect(group.users).not_to include group_user
      end
    end
  end

  describe 'PUT update' do
    let(:requester) { create(:group_member, :access_request, group: group) }

    before do
      group.add_owner(user)
      sign_in(user)
    end

    Gitlab::Access.options.each do |label, value|
      it "can change the access level to #{label}" do
        put :update, params: {
          group_member: { access_level: value },
          group_id: group,
          id: requester
        }, xhr: true

        expect(requester.reload.human_access).to eq(label)
      end
    end
  end

  describe 'DELETE destroy' do
    let(:member) { create(:group_member, :developer, group: group) }

    before do
      sign_in(user)
    end

    context 'when member is not found' do
      it 'returns 403' do
        delete :destroy, params: { group_id: group, id: 42 }

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when member is found' do
      context 'when user does not have enough rights' do
        before do
          group.add_developer(user)
        end

        it 'returns 403' do
          delete :destroy, params: { group_id: group, id: member }

          expect(response).to have_gitlab_http_status(403)
          expect(group.members).to include member
        end
      end

      context 'when user has enough rights' do
        before do
          group.add_owner(user)
        end

        it '[HTML] removes user from members' do
          delete :destroy, params: { group_id: group, id: member }

          expect(response).to set_flash.to 'User was successfully removed from group and any subresources.'
          expect(response).to redirect_to(group_group_members_path(group))
          expect(group.members).not_to include member
        end

        it '[JS] removes user from members' do
          delete :destroy, params: { group_id: group, id: member }, xhr: true

          expect(response).to be_successful
          expect(group.members).not_to include member
        end
      end
    end
  end

  describe 'DELETE leave' do
    before do
      sign_in(user)
    end

    context 'when member is not found' do
      it 'returns 404' do
        delete :leave, params: { group_id: group }

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when member is found' do
      context 'and is not an owner' do
        before do
          group.add_developer(user)
        end

        it 'removes user from members' do
          delete :leave, params: { group_id: group }

          expect(response).to set_flash.to "You left the \"#{group.name}\" group."
          expect(response).to redirect_to(dashboard_groups_path)
          expect(group.users).not_to include user
        end

        it 'supports json request' do
          delete :leave, params: { group_id: group }, format: :json

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['notice']).to eq "You left the \"#{group.name}\" group."
        end
      end

      context 'and is an owner' do
        before do
          group.add_owner(user)
        end

        it 'cannot removes himself from the group' do
          delete :leave, params: { group_id: group }

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'and is a requester' do
        before do
          group.request_access(user)
        end

        it 'removes user from members' do
          delete :leave, params: { group_id: group }

          expect(response).to set_flash.to 'Your access request to the group has been withdrawn.'
          expect(response).to redirect_to(group_path(group))
          expect(group.requesters).to be_empty
          expect(group.users).not_to include user
        end
      end
    end
  end

  describe 'POST request_access' do
    before do
      sign_in(user)
    end

    it 'creates a new GroupMember that is not a team member' do
      post :request_access, params: { group_id: group }

      expect(response).to set_flash.to 'Your request for access has been queued for review.'
      expect(response).to redirect_to(group_path(group))
      expect(group.requesters.exists?(user_id: user)).to be_truthy
      expect(group.users).not_to include user
    end
  end

  describe 'POST approve_access_request' do
    let(:member) { create(:group_member, :access_request, group: group) }

    before do
      sign_in(user)
    end

    context 'when member is not found' do
      it 'returns 403' do
        post :approve_access_request, params: { group_id: group, id: 42 }

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when member is found' do
      context 'when user does not have enough rights' do
        before do
          group.add_developer(user)
        end

        it 'returns 403' do
          post :approve_access_request, params: { group_id: group, id: member }

          expect(response).to have_gitlab_http_status(403)
          expect(group.members).not_to include member
        end
      end

      context 'when user has enough rights' do
        before do
          group.add_owner(user)
        end

        it 'adds user to members' do
          post :approve_access_request, params: { group_id: group, id: member }

          expect(response).to redirect_to(group_group_members_path(group))
          expect(group.members).to include member
        end
      end
    end
  end

  context 'with external authorization enabled' do
    before do
      enable_external_authorization_service_check
      group.add_owner(user)
      sign_in(user)
    end

    describe 'GET #index' do
      it 'is successful' do
        get :index, params: { group_id: group }

        expect(response).to have_gitlab_http_status(200)
      end
    end

    describe 'POST #create' do
      it 'is successful' do
        post :create, params: { group_id: group, users: user, access_level: Gitlab::Access::GUEST }

        expect(response).to have_gitlab_http_status(302)
      end
    end

    describe 'PUT #update' do
      it 'is successful' do
        put :update,
            params: {
              group_member: { access_level: Gitlab::Access::GUEST },
              group_id: group,
              id: membership
            },
            format: :js

        expect(response).to have_gitlab_http_status(200)
      end
    end

    describe 'DELETE #destroy' do
      it 'is successful' do
        delete :destroy, params: { group_id: group, id: membership }

        expect(response).to have_gitlab_http_status(302)
      end
    end

    describe 'POST #destroy' do
      it 'is successful' do
        sign_in(create(:user))

        post :request_access, params: { group_id: group }

        expect(response).to have_gitlab_http_status(302)
      end
    end

    describe 'POST #approve_request_access' do
      it 'is successful' do
        access_request = create(:group_member, :access_request, group: group)
        post :approve_access_request, params: { group_id: group, id: access_request }

        expect(response).to have_gitlab_http_status(302)
      end
    end

    describe 'DELETE #leave' do
      it 'is successful' do
        group.add_owner(create(:user))

        delete :leave, params: { group_id: group }

        expect(response).to have_gitlab_http_status(302)
      end
    end

    describe 'POST #resend_invite' do
      it 'is successful' do
        post :resend_invite, params: { group_id: group, id: membership }

        expect(response).to have_gitlab_http_status(302)
      end
    end
  end
end
