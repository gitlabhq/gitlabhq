# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsController, factory_default: :keep, feature_category: :code_review_workflow do
  include ExternalAuthorizationServiceHelpers
  include AdminModeHelper
  include Namespaces::DeletableHelper
  include ActionView::Helpers::TagHelper
  include SafeFormatHelper

  let_it_be(:group_organization) { current_organization }
  let_it_be_with_refind(:group) { create_default(:group, :public, organization: group_organization) }
  let_it_be_with_refind(:project) { create(:project, namespace: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:admin_with_admin_mode) { create(:admin) }
  let_it_be(:admin_without_admin_mode) { create(:admin) }
  let_it_be(:group_member) { create(:group_member, group: group, user: user) }
  let_it_be_with_reload(:owner) { group.add_owner(create(:user)).user }
  let_it_be(:maintainer) { group.add_maintainer(create(:user)).user }
  let_it_be_with_reload(:developer) { group.add_developer(create(:user)).user }
  let_it_be(:guest) { group.add_guest(create(:user)).user }

  before_all do
    group_organization.users = User.all
  end

  before do
    enable_admin_mode!(admin_with_admin_mode)
  end

  describe 'POST #create' do
    it 'allows creating a group' do
      sign_in(user)

      expect do
        post :create, params: { group: { name: 'new_group', path: 'new_group' } }
      end.to change { Group.count }.by(1)

      expect(response).to have_gitlab_http_status(:found)
    end

    context 'authorization' do
      it 'allows an admin to create a group' do
        sign_in(admin_without_admin_mode)

        expect do
          post :create, params: { group: { name: 'new_group', path: 'new_group' } }
        end.to change { Group.count }.by(1)

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when creating chat team' do
      before do
        stub_mattermost_setting(enabled: true)
      end

      it 'triggers Mattermost::CreateTeamService' do
        sign_in(user)

        expect_next_instance_of(::Mattermost::CreateTeamService) do |service|
          expect(service).to receive(:execute).and_return({ name: 'test-chat-team', id: 1 })
        end

        post :create, params: { group: { name: 'new_group', path: 'new_group', create_chat_team: 1 } }

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when creating subgroups' do
      [true, false].each do |can_create_group_status|
        context "and can_create_group is #{can_create_group_status}" do
          context 'and logged in as Owner' do
            it 'creates the subgroup' do
              owner.update_attribute(:can_create_group, can_create_group_status)
              sign_in(owner)

              post :create, params: { group: { parent_id: group.id, path: 'subgroup' } }

              expect(response).to be_redirect
              expect(response.location).to eq("http://test.host/#{group.path}/subgroup")
              expect(Group.last.organization.id).to eq(group_organization.id)
            end
          end

          context 'and logged in as Developer' do
            it 'renders the new template' do
              developer.update_attribute(:can_create_group, can_create_group_status)
              sign_in(developer)

              previous_group_count = Group.count

              post :create, params: { group: { parent_id: group.id, path: 'subgroup' } }

              expect(response).to render_template(:new)
              expect(Group.count).to eq(previous_group_count)
            end
          end
        end
      end
    end

    context 'when creating a top level group' do
      before do
        sign_in(developer)
      end

      context 'and can_create_group is enabled' do
        before do
          developer.update_attribute(:can_create_group, true)
        end

        it 'creates the Group' do
          original_group_count = Group.count

          post :create, params: { group: { path: 'subgroup' } }
          expect(Group.count).to eq(original_group_count + 1)
          expect(response).to be_redirect
          expect(Group.last.organization.id).to eq(Current.organization.id)
        end
      end

      context 'and can_create_group is disabled' do
        before do
          developer.update_attribute(:can_create_group, false)
        end

        it 'does not create the Group' do
          original_group_count = Group.count

          post :create, params: { group: { path: 'subgroup' } }

          expect(Group.count).to eq(original_group_count)
          expect(response).to render_template(:new)
        end
      end
    end

    context "malicious group name" do
      subject { post :create, params: { group: { name: "<script>alert('Mayday!');</script>", path: "invalid_group_url" } } }

      before do
        sign_in(user)
      end

      it { expect { subject }.not_to change { Group.count } }

      it { expect(subject).to render_template(:new) }
    end

    context 'when creating a group with `default_branch_protection` attribute' do
      before do
        sign_in(user)
      end

      subject do
        post :create, params: { group: { name: 'new_group', path: 'new_group', default_branch_protection: Gitlab::Access::PROTECTION_NONE } }
      end

      context 'for users who have the ability to create a group with `default_branch_protection`' do
        it 'creates group with the specified branch protection level' do
          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(Group.last.default_branch_protection).to eq(Gitlab::Access::PROTECTION_NONE)
        end
      end

      context 'for users who do not have the ability to create a group with `default_branch_protection`' do
        it 'does not create the group with the specified branch protection level' do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :create_group_with_default_branch_protection).and_return(false)

          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(Group.last.default_branch_protection).not_to eq(Gitlab::Access::PROTECTION_NONE)
        end
      end
    end

    context 'when creating a group with `default_branch_protection_defaults` attribute' do
      let(:protection_defaults) do
        {
          "allowed_to_push" => [{ 'access_level' => Gitlab::Access::MAINTAINER.to_s }],
          "allowed_to_merge" => [{ 'access_level' => Gitlab::Access::DEVELOPER.to_s }],
          "allow_force_push" => "false",
          "developer_can_initial_push" => "false"
        }
      end

      before do
        sign_in(user)
      end

      context 'for users who have the ability to create a group with `default_branch_protection_defaults`' do
        it 'creates group with the specified default branch protection level' do
          post :create, params: { group: { name: 'new_group', path: 'new_group', default_branch_protected: "true", default_branch_protection_defaults: protection_defaults } }, as: :json

          expect(response).to have_gitlab_http_status(:found)
          expect(Group.last.default_branch_protection_defaults).to eq(::Gitlab::Access::BranchProtection.protected_against_developer_pushes.stringify_keys)
        end

        it 'ignores default_branch_protection_defaults if default_branch_protected is set to false' do
          post :create, params: { group: { name: 'new_group', path: 'new_group', default_branch_protected: "false", default_branch_protection_defaults: protection_defaults } }, as: :json

          expect(response).to have_gitlab_http_status(:found)
          expect(Group.last.default_branch_protection_defaults).to eq(::Gitlab::Access::BranchProtection.protection_none.stringify_keys)
        end
      end

      context 'for users who do not have the ability to create a group with `default_branch_protection`' do
        it 'does not create the group with the specified branch protection level' do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :create_group_with_default_branch_protection).and_return(false)

          subject

          expect(response).to have_gitlab_http_status(:success)
          expect(Group.last.default_branch_protection_defaults).not_to eq(::Gitlab::Access::BranchProtection.protected_against_developer_pushes.stringify_keys)
        end
      end
    end

    context 'when creating a group with the `jobs_to_be_done` attribute present' do
      it 'sets the groups `jobs_to_be_done` value' do
        sign_in(user)
        post :create, params: { group: { name: 'new_group', path: 'new_group', jobs_to_be_done: 'other' } }
        expect(Group.last.jobs_to_be_done).to eq('other')
      end
    end
  end

  describe 'PUT transfer' do
    before do
      sign_in(user)
      stub_feature_flags(groups_and_projects_async_transfer: false)
    end

    context 'when transferring to a subgroup goes right' do
      let(:new_parent_group) { create(:group, :public) }
      let(:group) { create(:group, :public) }
      let!(:group_member) { create(:group_member, :owner, group: group, user: user) }
      let!(:new_parent_group_member) { create(:group_member, :owner, group: new_parent_group, user: user) }

      before do
        put :transfer,
          params: {
            id: group.to_param,
            new_parent_group_id: new_parent_group.id
          }
      end

      it 'returns a notice and redirects to the new path' do
        expect(flash[:notice]).to eq("Group '#{group.name}' was successfully transferred.")
        expect(response).to redirect_to("/#{new_parent_group.path}/#{group.path}")
      end
    end

    context 'when converting to a root group goes right' do
      let(:group) { create(:group, :public, :nested) }
      let!(:group_member) { create(:group_member, :owner, group: group, user: user) }

      before do
        put :transfer,
          params: {
            id: group.to_param,
            new_parent_group_id: ''
          }
      end

      it 'returns a notice and redirects to the new path' do
        expect(flash[:notice]).to eq("Group '#{group.name}' was successfully transferred.")
        expect(response).to redirect_to("/#{group.path}")
      end
    end

    context 'When the transfer goes wrong' do
      let(:new_parent_group) { create(:group, :public) }
      let(:group) { create(:group, :public) }
      let!(:group_member) { create(:group_member, :owner, group: group, user: user) }
      let!(:new_parent_group_member) { create(:group_member, :owner, group: new_parent_group, user: user) }

      before do
        # `proceed_to_transfer` is overridden in the prepended EE module
        # (EE::Groups::TransferService), so `allow_any_instance_of` can't
        # see it on the base class. Use `expect_next_instance_of` which
        # walks the prepended chain correctly.
        expect_next_instance_of(::Groups::TransferService) do |svc|
          allow(svc).to receive(:proceed_to_transfer)
            .and_raise(Gitlab::UpdatePathError, 'namespace directory cannot be moved')
        end

        put :transfer,
          params: {
            id: group.to_param,
            new_parent_group_id: new_parent_group.id
          }
      end

      it 'returns an alert and redirects to the current path' do
        expect(flash[:alert]).to eq "Transfer failed: namespace directory cannot be moved"
        expect(response).to redirect_to(edit_group_path(group))
      end
    end

    context 'when transferring an archived group' do
      let(:group) { create(:group, :public, owners: user) }
      let(:new_parent_group) { create(:group, :public, owners: user) }

      before do
        group.update!(archived: true)

        put :transfer,
          params: {
            id: group.to_param,
            new_parent_group_id: new_parent_group.id
          }
      end

      it 'returns not found' do
        expect(response).to have_gitlab_http_status(:not_found)
        expect(group.reload.parent).to be_nil
      end
    end

    context 'when the user is not allowed to transfer the group' do
      let(:new_parent_group) { create(:group, :public) }
      let(:group) { create(:group, :public) }
      let!(:group_member) { create(:group_member, :guest, group: group, user: user) }
      let!(:new_parent_group_member) { create(:group_member, :guest, group: new_parent_group, user: user) }

      before do
        put :transfer,
          params: {
            id: group.to_param,
            new_parent_group_id: new_parent_group.id
          }
      end

      it 'is denied' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'transferring when a project has container images' do
      let(:group) { create(:group, :public, :nested) }
      let(:project) { create(:project, namespace: group) }
      let!(:group_member) { create(:group_member, :owner, group: group, user: user) }

      before do
        stub_container_registry_config(enabled: true)
        stub_container_registry_tags(repository: /image/, tags: %w[rc1])
        create(:container_repository, project: project, name: :image)

        put :transfer,
          params: {
            id: group.to_param,
            new_parent_group_id: ''
          }
      end

      it 'does not allow the group to be transferred' do
        expect(controller).to set_flash[:alert].to match(/Docker images in their container registry/)
        expect(response).to redirect_to(edit_group_path(group))
      end
    end

    context 'when groups_and_projects_async_transfer feature flag is enabled' do
      let(:group) { create(:group, :public, owners: user) }
      let(:new_parent_group) { create(:group, :public, owners: user) }

      before do
        stub_feature_flags(groups_and_projects_async_transfer: true)
      end

      context 'when transferring to a new parent group' do
        it 'enqueues the async transfer worker and redirects' do
          expect(Namespaces::Groups::TransferWorker).to receive(:perform_async).with(
            group.id,
            new_parent_group.id,
            user.id
          )

          put :transfer,
            params: {
              id: group.to_param,
              new_parent_group_id: new_parent_group.id
            }

          expect(response).to redirect_to(group_path(group))
        end

        it 'transitions the group to transfer_scheduled state' do
          put :transfer,
            params: {
              id: group.to_param,
              new_parent_group_id: new_parent_group.id
            }

          expect(group.reload.state).to eq('transfer_scheduled')
        end

        it 'stores transfer metadata in state_metadata' do
          put :transfer,
            params: {
              id: group.to_param,
              new_parent_group_id: new_parent_group.id
            }

          metadata = group.reload.state_metadata
          expect(metadata['transfer_target_parent_id']).to eq(new_parent_group.id)
          expect(metadata['transfer_scheduled_by_user_id']).to eq(user.id)
          expect(metadata['transfer_scheduled_at']).to be_present
        end
      end

      context 'when transferring to root (no parent group)' do
        let(:group) { create(:group, :public, :nested, owners: user) }

        it 'enqueues the worker with nil parent group id' do
          expect(Namespaces::Groups::TransferWorker).to receive(:perform_async).with(
            group.id,
            nil,
            user.id
          )

          put :transfer,
            params: {
              id: group.to_param,
              new_parent_group_id: ''
            }

          expect(response).to redirect_to(group_path(group))
        end

        it 'stores nil transfer_target_parent_id in state_metadata' do
          put :transfer,
            params: {
              id: group.to_param,
              new_parent_group_id: ''
            }

          expect(group.reload.state_metadata['transfer_target_parent_id']).to be_nil
        end
      end

      context 'when the state transition fails' do
        before do
          group.update_column(:state, Group.states[:creation_in_progress])
        end

        it 'does not enqueue the worker and shows an error with last_error fallback' do
          expect(Namespaces::Groups::TransferWorker).not_to receive(:perform_async)

          put :transfer,
            params: {
              id: group.to_param,
              new_parent_group_id: new_parent_group.id
            }

          expect(flash[:alert]).to eq('Unable to initiate transfer. The group may already have a transfer in progress.')
          expect(response).to redirect_to(edit_group_path(group))
        end
      end

      context 'when the group is already in transfer_scheduled state with an active worker' do
        before do
          group.schedule_transfer!(transition_user: user)
          Gitlab::ExclusiveLease.new(
            Namespaces::Groups::TransferWorker.lease_key(group.id), timeout: 30.minutes
          ).try_obtain
        end

        it 'does not enqueue the worker and shows an error' do
          expect(Namespaces::Groups::TransferWorker).not_to receive(:perform_async)

          put :transfer,
            params: {
              id: group.to_param,
              new_parent_group_id: new_parent_group.id
            }

          expect(flash[:alert]).to eq('Unable to initiate transfer. The group may already have a transfer in progress.')
          expect(response).to redirect_to(edit_group_path(group))
        end
      end
    end
  end

  describe 'POST #export' do
    context 'when the user does not have permission to export the group' do
      before do
        sign_in(guest)
      end

      it 'returns an error' do
        post :export, params: { id: group.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user has permission to export the group' do
      before do
        sign_in(user)
      end

      it 'triggers the export job' do
        expect(GroupExportWorker).to receive(:perform_async).with(user.id, group.id, { exported_by_admin: false })

        post :export, params: { id: group.to_param }
      end

      it 'redirects to the edit page' do
        post :export, params: { id: group.to_param }

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when user is admin' do
      before do
        sign_in(admin_with_admin_mode)
      end

      it 'triggers the export job, and passes `exported_by_admin` correctly in the `params` hash' do
        expect(GroupExportWorker).to receive(:perform_async).with(admin_with_admin_mode.id, group.id, { exported_by_admin: true })

        post :export, params: { id: group.to_param }
      end
    end

    context 'when the endpoint receives requests above the rate limit' do
      before do
        sign_in(user)

        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:group_export, scope: anything).and_return(true)
      end

      it 'throttles the endpoint' do
        post :export, params: { id: group.to_param }

        expect(response.body).to eq('This endpoint has been requested too many times. Try again later.')
        expect(response).to have_gitlab_http_status :too_many_requests
      end
    end
  end

  describe 'GET #download_export' do
    let(:admin) { create(:admin) }
    let(:export_file) { fixture_file_upload('spec/fixtures/group_export.tar.gz') }

    before do
      enable_admin_mode!(admin)
    end

    context 'when there is a file available to download' do
      before do
        sign_in(admin)
        create(:import_export_upload, group: group, export_file: export_file, user: admin)
      end

      it 'sends the file' do
        get :download_export, params: { id: group.to_param }

        expect(response.body).to eq export_file.tempfile.read
      end
    end

    context 'when the file is no longer present on disk' do
      before do
        sign_in(admin)

        create(:import_export_upload, group: group, export_file: export_file, user: admin)
        group.export_file(admin).file.delete
      end

      it 'returns not found' do
        get :download_export, params: { id: group.to_param }

        expect(flash[:alert]).to include('file containing the export is not available yet')
        expect(response).to redirect_to(edit_group_path(group))
      end
    end

    context 'when there is no file available to download' do
      before do
        sign_in(admin)
      end

      it 'returns not found' do
        get :download_export, params: { id: group.to_param }

        expect(flash[:alert])
          .to eq 'Group export link has expired. Please generate a new export from your group settings.'

        expect(response).to redirect_to(edit_group_path(group))
      end
    end

    context 'when the user does not have the required permissions' do
      before do
        sign_in(guest)
      end

      it 'returns not_found' do
        get :download_export, params: { id: group.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the endpoint receives requests above the rate limit' do
      before do
        sign_in(admin)

        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:group_download_export, scope: anything).and_return(true)
      end

      it 'throttles the endpoint' do
        get :download_export, params: { id: group.to_param }

        expect(response.body).to eq('This endpoint has been requested too many times. Try again later.')
        expect(response).to have_gitlab_http_status :too_many_requests
      end
    end
  end

  describe 'external authorization' do
    before do
      group.add_owner(user)
      sign_in(user)
    end

    describe "GET #activity as JSON" do
      include DesignManagementTestHelpers

      let(:other_project) { create(:project, :public, group: group) }

      def get_activity
        get :activity, params: { format: :json, id: group.to_param }
      end

      before do
        enable_design_management
        issue = create(:issue, project: project)
        create(:event, :created, project: project, target: issue)
        create(:design_event, project: project)
        create(:design_event, project: other_project)

        sign_in(user)

        request.cookies[:event_filter] = 'all'
      end

      it 'returns count' do
        get_activity

        expect(json_response['count']).to eq(3)
      end
    end
  end
end
