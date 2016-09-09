require 'spec_helper'

describe Groups::GroupMembersController do
  let(:user)  { create(:user) }

  describe '#index' do
    let(:group) { create(:group) }

    before do
      group.add_owner(user)
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
    end

    it 'renders index with group members' do
      get :index, group_id: group

      expect(response).to have_http_status(200)
      expect(response).to render_template(:index)
    end
  end

  describe '#destroy' do
    let(:group) { create(:group, :public) }

    context 'when member is not found' do
      it 'returns 403' do
        delete :destroy, group_id: group,
                         id: 42

        expect(response).to have_http_status(403)
      end
    end

    context 'when member is found' do
      let(:user) { create(:user) }
      let(:group_user) { create(:user) }
      let(:member) do
        group.add_developer(group_user)
        group.members.find_by(user_id: group_user)
      end

      context 'when user does not have enough rights' do
        before do
          group.add_developer(user)
          sign_in(user)
        end

        it 'returns 403' do
          delete :destroy, group_id: group,
                           id: member

          expect(response).to have_http_status(403)
          expect(group.users).to include group_user
        end
      end

      context 'when user has enough rights' do
        before do
          group.add_owner(user)
          sign_in(user)
        end

        it '[HTML] removes user from members' do
          delete :destroy, group_id: group,
                           id: member

          expect(response).to set_flash.to 'User was successfully removed from group.'
          expect(response).to redirect_to(group_group_members_path(group))
          expect(group.users).not_to include group_user
        end

        it '[JS] removes user from members' do
          xhr :delete, :destroy, group_id: group,
                                 id: member

          expect(response).to be_success
          expect(group.users).not_to include group_user
        end
      end
    end
  end

  describe '#leave' do
    let(:group) { create(:group, :public) }
    let(:user) { create(:user) }

    context 'when member is not found' do
      before { sign_in(user) }

      it 'returns 403' do
        delete :leave, group_id: group

        expect(response).to have_http_status(403)
      end
    end

    context 'when member is found' do
      context 'and is not an owner' do
        before do
          group.add_developer(user)
          sign_in(user)
        end

        it 'removes user from members' do
          delete :leave, group_id: group

          expect(response).to set_flash.to "You left the \"#{group.name}\" group."
          expect(response).to redirect_to(dashboard_groups_path)
          expect(group.users).not_to include user
        end
      end

      context 'and is an owner' do
        before do
          group.add_owner(user)
          sign_in(user)
        end

        it 'cannot removes himself from the group' do
          delete :leave, group_id: group

          expect(response).to have_http_status(403)
        end
      end

      context 'and is a requester' do
        before do
          group.request_access(user)
          sign_in(user)
        end

        it 'removes user from members' do
          delete :leave, group_id: group

          expect(response).to set_flash.to 'Your access request to the group has been withdrawn.'
          expect(response).to redirect_to(group_path(group))
          expect(group.requesters).to be_empty
          expect(group.users).not_to include user
        end
      end
    end
  end

  describe '#request_access' do
    let(:group) { create(:group, :public) }
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it 'creates a new GroupMember that is not a team member' do
      post :request_access, group_id: group

      expect(response).to set_flash.to 'Your request for access has been queued for review.'
      expect(response).to redirect_to(group_path(group))
      expect(group.requesters.exists?(user_id: user)).to be_truthy
      expect(group.users).not_to include user
    end
  end

  describe '#approve_access_request' do
    let(:group) { create(:group, :public) }

    context 'when member is not found' do
      it 'returns 403' do
        post :approve_access_request, group_id: group,
                                      id: 42

        expect(response).to have_http_status(403)
      end
    end

    context 'when member is found' do
      let(:user) { create(:user) }
      let(:group_requester) { create(:user) }
      let(:member) do
        group.request_access(group_requester)
        group.requesters.find_by(user_id: group_requester)
      end

      context 'when user does not have enough rights' do
        before do
          group.add_developer(user)
          sign_in(user)
        end

        it 'returns 403' do
          post :approve_access_request, group_id: group,
                                        id: member

          expect(response).to have_http_status(403)
          expect(group.users).not_to include group_requester
        end
      end

      context 'when user has enough rights' do
        before do
          group.add_owner(user)
          sign_in(user)
        end

        it 'adds user to members' do
          post :approve_access_request, group_id: group,
                                        id: member

          expect(response).to redirect_to(group_group_members_path(group))
          expect(group.users).to include group_requester
        end
      end
    end
  end
end
