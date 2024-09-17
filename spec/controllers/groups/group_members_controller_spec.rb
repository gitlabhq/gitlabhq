# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupMembersController, feature_category: :groups_and_projects do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group, reload: true) { create(:group, :public) }

  before do
    travel_to DateTime.new(2019, 4, 1)
  end

  after do
    travel_back
  end

  describe 'GET index' do
    it 'renders index with 200 status code', :aggregate_failures do
      get :index, params: { group_id: group }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end

    context 'when user can manage members' do
      let_it_be(:invited) { create_list(:group_member, 3, :invited, group: group) }

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

      context 'when filtering by user type' do
        let_it_be(:service_account) { create(:user, :service_account) }

        before do
          group.add_developer(service_account)
        end

        it 'returns only service accounts' do
          get :index, params: { group_id: group, user_type: 'service_account' }

          expect(assigns(:members).map(&:user_id)).to match_array([service_account.id])
        end
      end

      context 'when there are import source users available' do
        it 'returns import source users count' do
          create(:import_source_user, :pending_reassignment, namespace: group)
          create(:import_source_user, :awaiting_approval, namespace: group)
          create(:import_source_user, :completed, namespace: group)

          get :index, params: { group_id: group }

          expect(assigns(:placeholder_users_count)).to eq(
            pagination: {
              total_items: 3,
              awaiting_reassignment_items: 2,
              reassigned_items: 1
            }
          )
        end

        context 'where there are no import source users available' do
          it 'returns 0 counts' do
            get :index, params: { group_id: group }

            expect(assigns(:placeholder_users_count)).to eq(
              pagination: {
                total_items: 0,
                awaiting_reassignment_items: 0,
                reassigned_items: 0
              }
            )
          end
        end

        context 'when importer_user_mapping feature flag is disabled' do
          it 'returns 0 counts' do
            stub_feature_flags(importer_user_mapping: false)

            create(:import_source_user, :pending_reassignment, namespace: group)

            get :index, params: { group_id: group }

            expect(assigns(:placeholder_users_count)).to eq(
              pagination: {
                total_items: 0,
                awaiting_reassignment_items: 0,
                reassigned_items: 0
              }
            )
          end
        end
      end
    end

    context 'when user cannot manage members' do
      before do
        sign_in(user)
      end

      it 'does not assign invited members' do
        get :index, params: { group_id: group }

        expect(assigns(:invited_members)).to be_nil
      end

      context 'when filtering by user type' do
        let_it_be(:service_account) { create(:user, :service_account) }

        before do
          group.add_developer(user)
          group.add_developer(service_account)
        end

        it 'returns only service accounts' do
          get :index, params: { group_id: group, user_type: 'service_account' }

          expect(assigns(:members).map(&:user_id)).to match_array([user.id, service_account.id])
        end
      end
    end

    context 'when user has owner access to subgroup' do
      let_it_be(:nested_group) { create(:group, parent: group) }
      let_it_be(:nested_group_user) { create(:user) }
      let_it_be(:shared_group) { create(:group, parent: group) }
      let_it_be(:shared_group_user) { create(:user) }

      before do
        group.add_owner(user)
        nested_group.add_owner(nested_group_user)
        shared_group.add_owner(shared_group_user)
        create(:group_group_link, shared_group: nested_group, shared_with_group: shared_group)
        sign_in(user)
      end

      it 'lists all group members including members from shared group by default' do
        get :index, params: { group_id: nested_group }

        expect(assigns(:members).map(&:user_id)).to contain_exactly(user.id, nested_group_user.id, shared_group_user.id)
      end

      it 'lists direct group members only' do
        get :index, params: { group_id: nested_group, with_inherited_permissions: 'exclude' }

        expect(assigns(:members).map(&:user_id)).to contain_exactly(nested_group_user.id)
      end

      it 'lists inherited and shared group members only' do
        get :index, params: { group_id: nested_group, with_inherited_permissions: 'only' }

        expect(assigns(:members).map(&:user_id)).to contain_exactly(user.id, shared_group_user.id)
      end
    end
  end

  describe 'PUT update' do
    let_it_be(:requester) { create(:group_member, :access_request, group: group) }

    before do
      group.add_owner(user)
      sign_in(user)
    end

    context 'access level' do
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

    context 'access expiry date' do
      subject do
        put :update, xhr: true, params: {
                                          group_member: {
                                            expires_at: expires_at
                                          },
                                          group_id: group,
                                          id: requester
                                        }
      end

      context 'when set to a date in the past' do
        let(:expires_at) { 2.days.ago }

        it 'does not update the member' do
          subject

          expect(requester.reload.expires_at).not_to eq(expires_at.to_date)
        end

        it 'returns error status' do
          subject

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          subject

          expect(json_response).to eq({ 'message' => 'Expires at cannot be a date in the past' })
        end
      end

      context 'when set to a date in the future' do
        let(:expires_at) { 5.days.from_now }

        it 'updates the member' do
          subject

          expect(requester.reload.expires_at).to eq(expires_at.to_date)
        end
      end
    end

    context 'expiration date' do
      let(:expiry_date) { 1.month.from_now.to_date }

      before do
        travel_to Time.now.utc.beginning_of_day

        put(
          :update,
          params: {
            group_member: { expires_at: expiry_date },
            group_id: group,
            id: requester
          },
          format: :json
        )
      end

      context 'when `expires_at` is set' do
        it 'returns correct json response' do
          expect(json_response).to include({
            "expires_soon" => false,
            "expires_at_formatted" => expiry_date.to_time.in_time_zone.to_fs(:medium)
          })
        end
      end

      context 'when `expires_at` is not set' do
        let(:expiry_date) { nil }

        it 'returns json response without expiration data' do
          expect(json_response).not_to have_key(:expires_soon)
          expect(json_response).not_to have_key(:expires_at_formatted)
        end
      end
    end
  end

  describe 'DELETE destroy' do
    let_it_be(:sub_group) { create(:group, parent: group) }
    let_it_be(:member) { create(:group_member, :developer, group: group) }
    let_it_be(:sub_member) { create(:group_member, :developer, group: sub_group, user: member.user) }

    before do
      sign_in(user)
    end

    context 'when member is not found' do
      it 'returns 403' do
        delete :destroy, params: { group_id: group, id: 42 }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when member is found' do
      context 'when user does not have enough rights' do
        before do
          group.add_developer(user)
        end

        it 'returns 403', :aggregate_failures do
          delete :destroy, params: { group_id: group, id: member }

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(group.members).to include member
        end
      end

      context 'when user has enough rights' do
        before do
          group.add_owner(user)
        end

        it '[HTML] removes user from members', :aggregate_failures do
          delete :destroy, params: { group_id: group, id: member }

          expect(controller).to set_flash.to 'User was successfully removed from group.'
          expect(response).to redirect_to(group_group_members_path(group))
          expect(group.members).not_to include member
          expect(sub_group.reload.members).to include sub_member
        end

        it '[HTML] removes user from members including subgroups and projects', :aggregate_failures do
          delete :destroy, params: { group_id: group, id: member, remove_sub_memberships: true }

          expect(controller).to set_flash.to 'User was successfully removed from group and any subgroups and projects.'
          expect(response).to redirect_to(group_group_members_path(group))
          expect(group.members).not_to include member
          expect(sub_group.reload.members).not_to include sub_member
        end

        it '[JS] removes user from members', :aggregate_failures do
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

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when member is found' do
      context 'and is not an owner' do
        before do
          group.add_developer(user)
        end

        it 'removes user from members', :aggregate_failures do
          delete :leave, params: { group_id: group }

          expect(controller).to set_flash.to "You left the \"#{group.name}\" group."
          expect(response).to redirect_to(dashboard_groups_path)
          expect(group).not_to have_user(user)
        end

        it 'supports json request', :aggregate_failures do
          delete :leave, params: { group_id: group }, format: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['notice']).to eq "You left the \"#{group.name}\" group."
        end
      end

      context 'and is an owner' do
        before do
          group.add_owner(user)
        end

        it 'cannot remove user from the group' do
          delete :leave, params: { group_id: group }

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'and there is a group project bot owner' do
          before do
            create(:group_member, :owner, source: group, user: create(:user, :project_bot))
          end

          it 'cannot remove user from the group' do
            delete :leave, params: { group_id: group }

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'with owners from a parent' do
          context 'when top-level group' do
            context 'with group sharing' do
              let!(:subgroup) { create(:group, parent: group) }

              before do
                create(:group_group_link, :owner, shared_group: group, shared_with_group: subgroup)
                create(:group_member, :owner, group: subgroup)
              end

              it 'does not allow removal of last direct group owner' do
                delete :leave, params: { group_id: group }

                expect(response).to have_gitlab_http_status(:forbidden)
              end
            end
          end

          context 'when subgroup' do
            let!(:subgroup) { create(:group, parent: group) }

            before do
              subgroup.add_owner(user)
            end

            it 'allows removal of last direct group owner', :aggregate_failures do
              delete :leave, params: { group_id: subgroup }

              expect(controller).to set_flash.to "You left the \"#{subgroup.human_name}\" group."
              expect(response).to redirect_to(dashboard_groups_path)
              expect(subgroup).not_to have_user(user)
            end
          end
        end

        context 'and there is another owner' do
          before do
            create(:group_member, :owner, source: group)
          end

          it 'removes user from members', :aggregate_failures do
            delete :leave, params: { group_id: group }

            expect(controller).to set_flash.to "You left the \"#{group.name}\" group."
            expect(response).to redirect_to(dashboard_groups_path)
            expect(group).not_to have_user(user)
          end
        end
      end

      context 'and is a requester' do
        let(:group) { create(:group, :public) }

        before do
          group.request_access(user)
        end

        it 'removes user from members', :aggregate_failures do
          delete :leave, params: { group_id: group }

          expect(controller).to set_flash.to 'Your access request to the group has been withdrawn.'
          expect(response).to redirect_to(group_path(group))
          expect(group.requesters).to be_empty
          expect(group).not_to have_user(user)
        end
      end
    end
  end

  describe 'POST request_access' do
    before do
      sign_in(user)
    end

    it 'creates a new GroupMember that is not a team member', :aggregate_failures do
      post :request_access, params: { group_id: group }

      expect(controller).to set_flash.to 'Your request for access has been queued for review.'
      expect(response).to redirect_to(group_path(group))
      expect(group.requesters.exists?(user_id: user)).to be_truthy
      expect(group).not_to have_user(user)
    end
  end

  describe 'POST approve_access_request' do
    let_it_be(:member) { create(:group_member, :access_request, group: group) }

    before do
      sign_in(user)
    end

    context 'when member is not found' do
      it 'returns 403' do
        post :approve_access_request, params: { group_id: group, id: 42 }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when member is found' do
      context 'when user does not have enough rights' do
        before do
          group.add_developer(user)
        end

        it 'returns 403', :aggregate_failures do
          post :approve_access_request, params: { group_id: group, id: member }

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(group.members).not_to include member
        end
      end

      context 'when user has enough rights' do
        before do
          group.add_owner(user)
        end

        it 'adds user to members', :aggregate_failures do
          post :approve_access_request, params: { group_id: group, id: member }

          expect(response).to redirect_to(group_group_members_path(group))
          expect(group.members).to include member
        end
      end
    end
  end

  context 'with external authorization enabled' do
    let_it_be(:membership) { create(:group_member, group: group) }

    before do
      enable_external_authorization_service_check
      group.add_owner(user)
      sign_in(user)
    end

    describe 'GET #index' do
      it 'is successful' do
        get :index, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'PUT #update' do
      it 'is successful' do
        put :update, params: {
          group_member: { access_level: Gitlab::Access::GUEST },
          group_id: group,
          id: membership
        }, format: :json

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'DELETE #destroy' do
      it 'is successful' do
        delete :destroy, params: { group_id: group, id: membership }

        expect(response).to have_gitlab_http_status(:see_other)
      end
    end

    describe 'POST #destroy' do
      it 'is successful' do
        sign_in(create(:user))

        post :request_access, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    describe 'POST #approve_request_access' do
      it 'is successful' do
        access_request = create(:group_member, :access_request, group: group)
        post :approve_access_request, params: { group_id: group, id: access_request }

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    describe 'DELETE #leave' do
      it 'is successful' do
        group.add_owner(create(:user))

        delete :leave, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    describe 'POST #resend_invite' do
      it 'is successful' do
        post :resend_invite, params: { group_id: group, id: membership }

        expect(response).to have_gitlab_http_status(:found)
      end
    end
  end
end
