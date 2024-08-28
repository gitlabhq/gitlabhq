# frozen_string_literal: true

require('spec_helper')

RSpec.describe Projects::ProjectMembersController, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:sub_group) { create(:group, parent: group) }
  let_it_be(:project, reload: true) { create(:project, :public) }
  let_it_be(:shared_group) { create(:group, parent: group) }
  let_it_be(:shared_group_user) { create(:user) }

  shared_examples_for 'controller actions' do
    before do
      travel_to DateTime.new(2019, 4, 1)
    end

    after do
      travel_back
    end

    describe 'GET index' do
      it 'has the project_members address with a 200 status code' do
        get :index, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'project members' do
        context 'when project belongs to group' do
          let_it_be(:user_in_group) { create(:user) }
          let_it_be(:project_in_group) { create(:project, :public, group: group) }

          before do
            group.add_owner(user_in_group)
            project_in_group.add_maintainer(user)
            shared_group.add_owner(shared_group_user)
            create(:group_group_link, shared_group: group, shared_with_group: shared_group)
            sign_in(user)
          end

          it 'lists all project members including members from shared group by default' do
            get :index, params: { namespace_id: project_in_group.namespace, project_id: project_in_group }

            expect(assigns(:project_members).map(&:user_id)).to contain_exactly(user.id, user_in_group.id, shared_group_user.id)
          end

          it 'lists direct project members only' do
            get :index, params: { namespace_id: project_in_group.namespace, project_id: project_in_group, with_inherited_permissions: 'exclude' }

            expect(assigns(:project_members).map(&:user_id)).to contain_exactly(user.id)
          end

          it 'lists inherited project members and shared group members only' do
            get :index, params: { namespace_id: project_in_group.namespace, project_id: project_in_group, with_inherited_permissions: 'only' }

            expect(assigns(:project_members).map(&:user_id)).to contain_exactly(user_in_group.id, shared_group_user.id)
          end
        end

        context 'when project belongs to a sub-group' do
          let_it_be(:user_in_group) { create(:user) }
          let_it_be(:project_in_group) { create(:project, :public, group: sub_group) }

          before do
            group.add_owner(user_in_group)
            project_in_group.add_maintainer(user)
            shared_group.add_owner(shared_group_user)
            create(:group_group_link, shared_group: sub_group, shared_with_group: shared_group)
            sign_in(user)
          end

          it 'lists all project members including members from shared group by default' do
            get :index, params: { namespace_id: project_in_group.namespace, project_id: project_in_group }

            expect(assigns(:project_members).map(&:user_id)).to contain_exactly(user.id, user_in_group.id, shared_group_user.id)
          end

          it 'lists direct project members only' do
            get :index, params: { namespace_id: project_in_group.namespace, project_id: project_in_group, with_inherited_permissions: 'exclude' }

            expect(assigns(:project_members).map(&:user_id)).to contain_exactly(user.id)
          end

          it 'lists inherited project members and shared group members only' do
            get :index, params: { namespace_id: project_in_group.namespace, project_id: project_in_group, with_inherited_permissions: 'only' }

            expect(assigns(:project_members).map(&:user_id)).to contain_exactly(user_in_group.id, shared_group_user.id)
          end
        end

        context 'when invited project members are present' do
          let!(:invited_member) { create(:project_member, :invited, project: project) }

          before do
            project.add_maintainer(user)
            sign_in(user)
          end

          it 'excludes the invited members from project members list' do
            get :index, params: { namespace_id: project.namespace, project_id: project }

            expect(assigns(:project_members).map(&:invite_email)).not_to contain_exactly(invited_member.invite_email)
          end
        end

        shared_examples 'users are invited through groups' do
          let_it_be(:invited_group_member) { create(:user) }

          it 'lists invited group members by default' do
            get :index, params: { namespace_id: project.namespace, project_id: project }

            expect(assigns(:project_members).map(&:user_id)).to include(invited_group_member.id)
          end
        end

        context 'when invited group members are present' do
          before do
            group.add_owner(invited_group_member)

            project.invited_groups << group
            project.add_maintainer(user)

            sign_in(user)
          end

          include_examples 'users are invited through groups'
        end

        context 'when group is invited to project parent' do
          let_it_be(:parent_group) { create(:group, :public) }
          let_it_be(:project, reload: true) { create(:project, :public, namespace: parent_group) }

          before do
            group.add_owner(invited_group_member)

            parent_group.shared_with_groups << group
            project.add_maintainer(user)

            sign_in(user)
          end

          include_examples 'users are invited through groups'
        end
      end

      context 'invited members' do
        let_it_be(:invited_member) { create(:project_member, :invited, project: project) }

        before do
          sign_in(user)
        end

        context 'when user has `admin_project_member` permissions' do
          before do
            project.add_maintainer(user)
          end

          it 'lists invited members' do
            get :index, params: { namespace_id: project.namespace, project_id: project }

            expect(assigns(:invited_members).map(&:invite_email)).to contain_exactly(invited_member.invite_email)
          end
        end

        context 'when user does not have `admin_project_member` permissions' do
          it 'does not list invited members' do
            get :index, params: { namespace_id: project.namespace, project_id: project }

            expect(assigns(:invited_members)).to be_nil
          end
        end
      end

      context 'access requests' do
        let_it_be(:access_requester_user) { create(:user) }

        before do
          project.request_access(access_requester_user)
          sign_in(user)
        end

        context 'when user has `admin_project_member` permissions' do
          before do
            project.add_maintainer(user)
          end

          it 'lists access requests' do
            get :index, params: { namespace_id: project.namespace, project_id: project }

            expect(assigns(:requesters).map(&:user_id)).to contain_exactly(access_requester_user.id)
          end
        end

        context 'when user does not have `admin_project_member` permissions' do
          it 'does not list access requests' do
            get :index, params: { namespace_id: project.namespace, project_id: project }

            expect(assigns(:requesters)).to be_nil
          end
        end
      end
    end

    describe 'PUT update' do
      let_it_be(:requester) { create(:project_member, :access_request, project: project) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      context 'access level' do
        Gitlab::Access.options.each do |label, value|
          it "can change the access level to #{label}" do
            params = {
              project_member: { access_level: value },
              namespace_id: project.namespace,
              project_id: project,
              id: requester
            }

            put :update, params: params, xhr: true

            expect(requester.reload.human_access).to eq(label)
          end
        end

        describe 'managing project direct owners' do
          context 'when a Maintainer tries to elevate another user to OWNER' do
            it 'does not allow the operation' do
              params = {
                project_member: { access_level: Gitlab::Access::OWNER },
                namespace_id: project.namespace,
                project_id: project,
                id: requester
              }

              put :update, params: params, xhr: true

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end

          context 'when a user with OWNER access tries to elevate another user to OWNER' do
            # inherited owner role via personal project association
            let(:user) { project.first_owner }

            before do
              sign_in(user)
            end

            it 'returns success' do
              params = {
                project_member: { access_level: Gitlab::Access::OWNER },
                namespace_id: project.namespace,
                project_id: project,
                id: requester
              }

              put :update, params: params, xhr: true

              expect(response).to have_gitlab_http_status(:ok)
              expect(requester.reload.access_level).to eq(Gitlab::Access::OWNER)
            end
          end
        end
      end

      context 'access expiry date' do
        subject do
          put :update, xhr: true, params: {
                                            project_member: {
                                              expires_at: expires_at
                                            },
                                            namespace_id: project.namespace,
                                            project_id: project,
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
              project_member: { expires_at: expiry_date },
              namespace_id: project.namespace,
              project_id: project,
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
      let_it_be(:member) { create(:project_member, :developer, project: project) }

      before do
        sign_in(user)
      end

      context 'when member is not found' do
        it 'returns 404' do
          delete :destroy, params: {
                             namespace_id: project.namespace,
                             project_id: project,
                             id: 42
                           }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when member is found' do
        context 'when user does not have enough rights' do
          context 'when user does not have rights to manage other members' do
            before do
              project.add_developer(user)
            end

            it 'returns 404', :aggregate_failures do
              delete :destroy, params: {
                namespace_id: project.namespace,
                project_id: project,
                id: member
              }

              expect(response).to have_gitlab_http_status(:not_found)
              expect(project.members).to include member
            end
          end

          context 'when user does not have rights to manage Owner members' do
            let_it_be(:member) { create(:project_member, project: project, access_level: Gitlab::Access::OWNER) }

            before do
              project.add_maintainer(user)
            end

            it 'returns 403', :aggregate_failures do
              delete :destroy, params: {
                namespace_id: project.namespace,
                project_id: project,
                id: member
              }

              expect(response).to have_gitlab_http_status(:forbidden)
              expect(project.members).to include member
            end
          end
        end

        context 'when user has enough rights' do
          before do
            project.add_maintainer(user)
          end

          it '[HTML] removes user from members', :aggregate_failures do
            delete :destroy, params: {
                               namespace_id: project.namespace,
                               project_id: project,
                               id: member
                             }

            expect(response).to redirect_to(
              project_project_members_path(project)
            )
            expect(project.members).not_to include member
          end

          it '[JS] removes user from members', :aggregate_failures do
            delete :destroy, params: {
              namespace_id: project.namespace,
              project_id: project,
              id: member
            }, xhr: true

            expect(response).to be_successful
            expect(project.members).not_to include member
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
          delete :leave, params: {
                           namespace_id: project.namespace,
                           project_id: project
                         }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when member is found' do
        context 'and is not an owner' do
          before do
            project.add_developer(user)
          end

          it 'removes user from members', :aggregate_failures do
            delete :leave, params: {
                             namespace_id: project.namespace,
                             project_id: project
                           }

            expect(controller).to set_flash.to "You left the \"#{project.human_name}\" project."
            expect(response).to redirect_to(dashboard_projects_path)
            expect(project.users).not_to include user
          end
        end

        context 'and is an owner' do
          let(:project) { create(:project, namespace: user.namespace) }

          before do
            project.add_maintainer(user)
          end

          it 'cannot remove themselves from the project' do
            delete :leave, params: {
                             namespace_id: project.namespace,
                             project_id: project
                           }

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'and is a requester' do
          before do
            project.request_access(user)
          end

          it 'removes user from members', :aggregate_failures do
            delete :leave, params: {
                             namespace_id: project.namespace,
                             project_id: project
                           }

            expect(controller).to set_flash.to 'Your access request to the project has been withdrawn.'
            expect(response).to redirect_to(project_path(project))
            expect(project.requesters).to be_empty
            expect(project.users).not_to include user
          end
        end
      end
    end

    describe 'POST request_access' do
      before do
        sign_in(user)
      end

      it 'creates a new ProjectMember that is not a team member', :aggregate_failures do
        post :request_access, params: {
                                namespace_id: project.namespace,
                                project_id: project
                              }

        expect(controller).to set_flash.to 'Your request for access has been queued for review.'
        expect(response).to redirect_to(
          project_path(project)
        )
        expect(project.requesters.exists?(user_id: user)).to be_truthy
        expect(project.users).not_to include user
      end
    end

    describe 'POST approve' do
      let_it_be(:member) { create(:project_member, :access_request, project: project) }

      before do
        sign_in(user)
      end

      context 'when member is not found' do
        it 'returns 404' do
          post :approve_access_request, params: {
                                          namespace_id: project.namespace,
                                          project_id: project,
                                          id: 42
                                        }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when member is found' do
        context 'when user does not have rights to manage other members' do
          before do
            project.add_developer(user)
          end

          it 'returns 404', :aggregate_failures do
            post :approve_access_request, params: {
                                            namespace_id: project.namespace,
                                            project_id: project,
                                            id: member
                                          }

            expect(response).to have_gitlab_http_status(:not_found)
            expect(project.members).not_to include member
          end
        end

        context 'when user has enough rights' do
          before do
            project.add_maintainer(user)
          end

          it 'adds user to members', :aggregate_failures do
            post :approve_access_request, params: {
                                            namespace_id: project.namespace,
                                            project_id: project,
                                            id: member
                                          }

            expect(response).to redirect_to(
              project_project_members_path(project)
            )
            expect(project.members).to include member
          end
        end
      end
    end

    describe 'POST resend_invite' do
      let_it_be(:member) { create(:project_member, project: project) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      it 'is successful' do
        post :resend_invite, params: { namespace_id: project.namespace, project_id: project, id: member }

        expect(response).to have_gitlab_http_status(:found)
      end
    end
  end

  it_behaves_like 'controller actions'
end
