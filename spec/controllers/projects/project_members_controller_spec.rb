# frozen_string_literal: true

require('spec_helper')

RSpec.describe Projects::ProjectMembersController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project, reload: true) { create(:project, :public) }

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
          sign_in(user)
        end

        it 'lists inherited project members by default' do
          get :index, params: { namespace_id: project_in_group.namespace, project_id: project_in_group }

          expect(assigns(:project_members).map(&:user_id)).to contain_exactly(user.id, user_in_group.id)
        end

        it 'lists direct project members only' do
          get :index, params: { namespace_id: project_in_group.namespace, project_id: project_in_group, with_inherited_permissions: 'exclude' }

          expect(assigns(:project_members).map(&:user_id)).to contain_exactly(user.id)
        end

        it 'lists inherited project members only' do
          get :index, params: { namespace_id: project_in_group.namespace, project_id: project_in_group, with_inherited_permissions: 'only' }

          expect(assigns(:project_members).map(&:user_id)).to contain_exactly(user_in_group.id)
        end
      end

      context 'when invited members are present' do
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
    end

    context 'group links' do
      let_it_be(:project_group_link) { create(:project_group_link, project: project, group: group) }

      it 'lists group links' do
        get :index, params: { namespace_id: project.namespace, project_id: project }

        expect(assigns(:group_links).map(&:id)).to contain_exactly(project_group_link.id)
      end

      context 'when `search_groups` param is present' do
        let(:group_2) { create(:group, :public, name: 'group_2') }
        let!(:project_group_link_2) { create(:project_group_link, project: project, group: group_2) }

        it 'lists group links that match search' do
          get :index, params: { namespace_id: project.namespace, project_id: project, search_groups: 'group_2' }

          expect(assigns(:group_links).map(&:id)).to contain_exactly(project_group_link_2.id)
        end
      end
    end

    context 'invited members' do
      let_it_be(:invited_member) { create(:project_member, :invited, project: project) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      context 'when user has `admin_project_member` permissions' do
        before do
          allow(controller.helpers).to receive(:can_manage_project_members?).with(project).and_return(true)
        end

        it 'lists invited members' do
          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(assigns(:invited_members).map(&:invite_email)).to contain_exactly(invited_member.invite_email)
        end
      end

      context 'when user does not have `admin_project_member` permissions' do
        before do
          allow(controller.helpers).to receive(:can_manage_project_members?).with(project).and_return(false)
        end

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
        project.add_maintainer(user)
        sign_in(user)
      end

      context 'when user has `admin_project_member` permissions' do
        before do
          allow(controller.helpers).to receive(:can_manage_project_members?).with(project).and_return(true)
        end

        it 'lists access requests' do
          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(assigns(:requesters).map(&:user_id)).to contain_exactly(access_requester_user.id)
        end
      end

      context 'when user does not have `admin_project_member` permissions' do
        before do
          allow(controller.helpers).to receive(:can_manage_project_members?).with(project).and_return(false)
        end

        it 'does not list access requests' do
          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(assigns(:requesters)).to be_nil
        end
      end
    end
  end

  describe 'POST create' do
    let_it_be(:project_user) { create(:user) }

    before do
      sign_in(user)
    end

    context 'when user does not have enough rights' do
      before do
        project.add_developer(user)
      end

      it 'returns 404', :aggregate_failures do
        post :create, params: {
                        namespace_id: project.namespace,
                        project_id: project,
                        user_ids: project_user.id,
                        access_level: Gitlab::Access::GUEST
                      }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(project.users).not_to include project_user
      end
    end

    context 'when user has enough rights' do
      before do
        project.add_maintainer(user)
      end

      it 'adds user to members', :aggregate_failures, :snowplow do
        post :create, params: {
                        namespace_id: project.namespace,
                        project_id: project,
                        user_ids: project_user.id,
                        access_level: Gitlab::Access::GUEST
                      }

        expect(controller).to set_flash.to 'Users were successfully added.'
        expect(response).to redirect_to(project_project_members_path(project))
        expect(project.users).to include project_user
        expect_snowplow_event(
          category: 'Members::CreateService',
          action: 'create_member',
          label: 'project-members-page',
          property: 'existing_user',
          user: user
        )
      end

      it 'adds no user to members', :aggregate_failures do
        expect_next_instance_of(Members::CreateService) do |instance|
          expect(instance).to receive(:execute).and_return(status: :failure, message: 'Message')
        end

        post :create, params: {
                        namespace_id: project.namespace,
                        project_id: project,
                        user_ids: '',
                        access_level: Gitlab::Access::GUEST
                      }

        expect(controller).to set_flash.to 'Message'
        expect(response).to redirect_to(project_project_members_path(project))
      end
    end

    context 'adding project bot' do
      let_it_be(:project_bot) { create(:user, :project_bot) }

      before do
        project.add_maintainer(user)

        unrelated_project = create(:project)
        unrelated_project.add_maintainer(project_bot)
      end

      it 'returns error', :aggregate_failures do
        post :create, params: {
          namespace_id: project.namespace,
          project_id: project,
          user_ids: project_bot.id,
          access_level: Gitlab::Access::GUEST
        }

        expect(flash[:alert]).to include('project bots cannot be added to other groups / projects')
        expect(response).to redirect_to(project_project_members_path(project))
      end
    end

    context 'access expiry date' do
      before do
        project.add_maintainer(user)
      end

      subject do
        post :create, params: {
                        namespace_id: project.namespace,
                        project_id: project,
                        user_ids: project_user.id,
                        access_level: Gitlab::Access::GUEST,
                        expires_at: expires_at
                      }
      end

      context 'when set to a date in the past' do
        let(:expires_at) { 2.days.ago }

        it 'does not add user to members', :aggregate_failures do
          subject

          expect(flash[:alert]).to include('Expires at cannot be a date in the past')
          expect(response).to redirect_to(project_project_members_path(project))
          expect(project.users).not_to include project_user
        end
      end

      context 'when set to a date in the future' do
        let(:expires_at) { 5.days.from_now }

        it 'adds user to members', :aggregate_failures do
          subject

          expect(controller).to set_flash.to 'Users were successfully added.'
          expect(response).to redirect_to(project_project_members_path(project))
          expect(project.users).to include project_user
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
          expect(json_response).to eq({
            "expires_in" => "about 1 month",
            "expires_soon" => false,
            "expires_at_formatted" => expiry_date.to_time.in_time_zone.to_s(:medium)
          })
        end
      end

      context 'when `expires_at` is not set' do
        let(:expiry_date) { nil }

        it 'returns empty json response' do
          expect(json_response).to be_empty
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
      context 'when user does not have enough rights' do
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

  describe 'POST apply_import' do
    let_it_be(:another_project) { create(:project, :private) }
    let_it_be(:member) { create(:user) }

    before do
      project.add_maintainer(user)
      another_project.add_guest(member)
      sign_in(user)
    end

    shared_context 'import applied' do
      before do
        post(:apply_import, params: {
                              namespace_id: project.namespace,
                              project_id: project,
                              source_project_id: another_project.id
                            })
      end
    end

    context 'when user can access source project members' do
      before do
        another_project.add_guest(user)
      end

      include_context 'import applied'

      it 'imports source project members', :aggregate_failures do
        expect(project.team_members).to include member
        expect(controller).to set_flash.to 'Successfully imported'
        expect(response).to redirect_to(
          project_project_members_path(project)
        )
      end
    end

    context 'when user is not member of a source project' do
      include_context 'import applied'

      it 'does not import team members' do
        expect(project.team_members).not_to include member
      end

      it 'responds with not found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST create' do
    let_it_be(:stranger) { create(:user) }

    context 'when creating owner' do
      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      it 'does not create a member' do
        expect do
          post :create, params: {
                          user_ids: stranger.id,
                          namespace_id: project.namespace,
                          access_level: Member::OWNER,
                          project_id: project
                        }
        end.to change { project.members.count }.by(0)
      end
    end

    context 'when create maintainer' do
      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      it 'creates a member' do
        expect do
          post :create, params: {
                          user_ids: stranger.id,
                          namespace_id: project.namespace,
                          access_level: Member::MAINTAINER,
                          project_id: project
                        }
        end.to change { project.members.count }.by(1)
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
