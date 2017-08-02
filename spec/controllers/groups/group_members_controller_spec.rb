require 'spec_helper'

describe Groups::GroupMembersController do
  let(:user)  { create(:user) }
  let(:group) { create(:group, :public, :access_requestable) }

  describe 'GET index' do
    it 'renders index with 200 status code' do
      get :index, group_id: group

      expect(response).to have_http_status(200)
      expect(response).to render_template(:index)
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
        post :create, group_id: group,
                      user_ids: group_user.id,
                      access_level: Gitlab::Access::GUEST

        expect(response).to have_http_status(403)
        expect(group.users).not_to include group_user
      end
    end

    context 'when user has enough rights' do
      before do
        group.add_owner(user)
      end

      it 'adds user to members' do
        post :create, group_id: group,
                      user_ids: group_user.id,
                      access_level: Gitlab::Access::GUEST

        expect(response).to set_flash.to 'Users were successfully added.'
        expect(response).to redirect_to(group_group_members_path(group))
        expect(group.users).to include group_user
      end

      it 'adds no user to members' do
        post :create, group_id: group,
                      user_ids: '',
                      access_level: Gitlab::Access::GUEST

        expect(response).to set_flash.to 'No users specified.'
        expect(response).to redirect_to(group_group_members_path(group))
        expect(group.users).not_to include group_user
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
        delete :destroy, group_id: group, id: 42

        expect(response).to have_http_status(403)
      end
    end

    context 'when member is found' do
      context 'when user does not have enough rights' do
        before do
          group.add_developer(user)
        end

        it 'returns 403' do
          delete :destroy, group_id: group, id: member

          expect(response).to have_http_status(403)
          expect(group.members).to include member
        end
      end

      context 'when user has enough rights' do
        before do
          group.add_owner(user)
        end

        it '[HTML] removes user from members' do
          delete :destroy, group_id: group, id: member

          expect(response).to set_flash.to 'User was successfully removed from group.'
          expect(response).to redirect_to(group_group_members_path(group))
          expect(group.members).not_to include member
        end

        it '[JS] removes user from members' do
          xhr :delete, :destroy, group_id: group, id: member

          expect(response).to be_success
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
        delete :leave, group_id: group

        expect(response).to have_http_status(404)
      end
    end

    context 'when member is found' do
      context 'and is not an owner' do
        before do
          group.add_developer(user)
        end

        it 'removes user from members' do
          delete :leave, group_id: group

          expect(response).to set_flash.to "You left the \"#{group.name}\" group."
          expect(response).to redirect_to(dashboard_groups_path)
          expect(group.users).not_to include user
        end

        it 'supports json request' do
          delete :leave, group_id: group, format: :json

          expect(response).to have_http_status(200)
          expect(json_response['notice']).to eq "You left the \"#{group.name}\" group."
        end
      end

      context 'and is an owner' do
        before do
          group.add_owner(user)
        end

        it 'cannot removes himself from the group' do
          delete :leave, group_id: group

          expect(response).to have_http_status(403)
        end
      end
    end
  end

  describe 'POST request_access' do
    before do
      sign_in(user)
    end

    it 'creates a new GroupAccessRequest that is not a team member' do
      post :request_access, group_id: group

      expect(response).to set_flash.to 'Your request for access has been queued for review.'
      expect(response).to redirect_to(group_path(group))
      expect(group.access_requests.exists?(user_id: user)).to be_truthy
      expect(group.users).not_to include user
    end
  end

  describe 'DELETE withdraw_access_request' do
    context 'when the current_user has requested access to the group' do
      let!(:access_request) { group.request_access(user) }

      before do
        sign_in(user)
      end

      it 'redirects with success message' do
        delete :withdraw_access_request, group_id: group

        expect(response).to set_flash.to /Your access request .* has been withdrawn/
        expect(response).to redirect_to(group)
      end

      it 'destroys the access request' do
        delete :withdraw_access_request, group_id: group

        expect(group.access_requests.where(user: user)).not_to exist
      end
    end

    context 'when the current_user has not requested access to the group' do
      let(:other_user) { create(:user) }
      let!(:other_access_request) { group.request_access(other_user) }

      before do
        sign_in(user)
      end

      it 'responds 404 Not Found' do
        delete :withdraw_access_request, group_id: group

        expect(response).to have_http_status(404)
      end

      it "does not destroy another user's access request" do
        delete :withdraw_access_request, group_id: group

        expect(group.access_requests.where(user: other_user)).to exist
      end
    end
  end

  describe 'POST approve_access_request' do
    let(:member) { create(:group_member, :access_request, group: group) }

    before do
      sign_in(user)
    end

    context 'when member is not found' do
      it 'returns 403' do
        post :approve_access_request, group_id: group, id: 42

        expect(response).to have_http_status(403)
      end
    end

    context 'when member is found' do
      context 'when user does not have enough rights' do
        before do
          group.add_developer(user)
        end

        it 'returns 403' do
          post :approve_access_request, group_id: group, id: member

          expect(response).to have_http_status(403)
          expect(group.members).not_to include member
        end
      end

      context 'when user has enough rights' do
        before do
          group.add_owner(user)
        end

        it 'adds user to members' do
          post :approve_access_request, group_id: group, id: member

          expect(response).to redirect_to(group_group_members_path(group))
          expect(group.members).to include member
        end
      end
    end
  end
end
