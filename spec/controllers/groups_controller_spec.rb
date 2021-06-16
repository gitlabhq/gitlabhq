# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsController, factory_default: :keep do
  include ExternalAuthorizationServiceHelpers
  include AdminModeHelper

  let_it_be_with_refind(:group) { create_default(:group, :public) }
  let_it_be_with_refind(:project) { create(:project, namespace: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:admin_with_admin_mode) { create(:admin) }
  let_it_be(:admin_without_admin_mode) { create(:admin) }
  let_it_be(:group_member) { create(:group_member, group: group, user: user) }
  let_it_be(:owner) { group.add_owner(create(:user)).user }
  let_it_be(:maintainer) { group.add_maintainer(create(:user)).user }
  let_it_be(:developer) { group.add_developer(create(:user)).user }
  let_it_be(:guest) { group.add_guest(create(:user)).user }

  before do
    enable_admin_mode!(admin_with_admin_mode)
  end

  shared_examples 'member with ability to create subgroups' do
    it 'renders the new page' do
      sign_in(member)

      get :new, params: { parent_id: group.id }

      expect(response).to render_template(:new)
    end
  end

  shared_examples 'member without ability to create subgroups' do
    it 'renders the 404 page' do
      sign_in(member)

      get :new, params: { parent_id: group.id }

      expect(response).not_to render_template(:new)
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'details view' do
    let(:namespace) { group }

    it { is_expected.to render_template('groups/show') }

    context 'as atom' do
      let!(:event) { create(:event, project: project) }
      let(:format) { :atom }

      it { is_expected.to render_template('groups/show') }

      it 'assigns events for all the projects in the group', :sidekiq_might_not_need_inline do
        subject
        expect(assigns(:events).map(&:id)).to contain_exactly(event.id)
      end
    end
  end

  describe 'GET #show' do
    before do
      sign_in(user)
    end

    let(:format) { :html }

    subject { get :show, params: { id: group.to_param }, format: format }

    context 'when the group is not importing' do
      it_behaves_like 'details view'
    end

    context 'when the group is importing' do
      before do
        create(:group_import_state, group: group)
      end

      it 'redirects to the import status page' do
        expect(subject).to redirect_to group_import_path(group)
      end
    end
  end

  describe 'GET #details' do
    before do
      sign_in(user)
    end

    let(:format) { :html }

    subject { get :details, params: { id: group.to_param }, format: format }

    it_behaves_like 'details view'
  end

  describe 'GET edit' do
    it 'sets the badge API endpoint' do
      sign_in(owner)

      get :edit, params: { id: group.to_param }

      expect(assigns(:badge_api_endpoint)).not_to be_nil
    end
  end

  describe 'GET #new' do
    context 'when creating subgroups' do
      [true, false].each do |can_create_group_status|
        context "and can_create_group is #{can_create_group_status}" do
          before do
            User.where(id: [admin_with_admin_mode, admin_without_admin_mode, owner, maintainer, developer, guest]).update_all(can_create_group: can_create_group_status)
          end

          [:admin_with_admin_mode, :owner, :maintainer].each do |member_type|
            context "and logged in as #{member_type.capitalize}" do
              it_behaves_like 'member with ability to create subgroups' do
                let(:member) { send(member_type) }
              end
            end
          end

          [:guest, :developer, :admin_without_admin_mode].each do |member_type|
            context "and logged in as #{member_type.capitalize}" do
              it_behaves_like 'member without ability to create subgroups' do
                let(:member) { send(member_type) }
              end
            end
          end
        end
      end
    end
  end

  describe 'GET #activity' do
    context 'as json' do
      before do
        sign_in(user)
      end

      it 'includes events from all projects in group and subgroups', :sidekiq_might_not_need_inline do
        2.times do
          project = create(:project, group: group)
          create(:event, project: project)
        end
        subgroup = create(:group, parent: group)
        project = create(:project, group: subgroup)
        create(:event, project: project)

        get :activity, params: { id: group.to_param }, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['count']).to eq(3)
        expect(assigns(:projects).limit_value).to be_nil
      end
    end

    context 'when user has no permission to see the event' do
      let(:project_with_restricted_access) do
        create(:project, :public, issues_access_level: ProjectFeature::PRIVATE, group: group)
      end

      before do
        create(:event, project: project)
        create(:event, :created, project: project_with_restricted_access, target: create(:issue))

        group.add_guest(user)

        sign_in(user)
      end

      it 'filters out invisible event' do
        get :activity, params: { id: group.to_param }, format: :json

        expect(json_response['count']).to eq(1)
      end
    end
  end

  describe 'POST #create' do
    it 'allows creating a group' do
      sign_in(user)

      expect do
        post :create, params: { group: { name: 'new_group', path: "new_group" } }
      end.to change { Group.count }.by(1)

      expect(response).to have_gitlab_http_status(:found)
    end

    context 'authorization' do
      it 'allows an admin to create a group' do
        sign_in(create(:admin))

        expect do
          post :create, params: { group: { name: 'new_group', path: "new_group" } }
        end.to change { Group.count }.by(1)

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
              expect(response.body).to match(%r{http://test.host/#{group.path}/subgroup})
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
          allow(Ability).to receive(:allowed?).with(user, :create_group_with_default_branch_protection) { false }

          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(Group.last.default_branch_protection).not_to eq(Gitlab::Access::PROTECTION_NONE)
        end
      end
    end

    context 'when creating a group with captcha protection' do
      before do
        sign_in(user)

        stub_application_setting(recaptcha_enabled: true)
      end

      after do
        # Avoid test ordering issue and ensure `verify_recaptcha` returns true
        unless Recaptcha.configuration.skip_verify_env.include?('test')
          Recaptcha.configuration.skip_verify_env << 'test'
        end
      end

      it 'displays an error when the reCAPTCHA is not solved' do
        allow(controller).to receive(:verify_recaptcha).and_return(false)

        post :create, params: { group: { name: 'new_group', path: "new_group" } }

        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq(_('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'))
      end

      it 'allows creating a group when the reCAPTCHA is solved' do
        expect do
          post :create, params: { group: { name: 'new_group', path: "new_group" } }
        end.to change { Group.count }.by(1)

        expect(response).to have_gitlab_http_status(:found)
      end

      it 'allows creating a sub-group without checking the captcha' do
        expect(controller).not_to receive(:verify_recaptcha)

        expect do
          post :create, params: { group: { name: 'new_group', path: "new_group", parent_id: group.id } }
        end.to change { Group.count }.by(1)

        expect(response).to have_gitlab_http_status(:found)
      end

      context 'with feature flag switched off' do
        before do
          stub_feature_flags(recaptcha_on_top_level_group_creation: false)
        end

        it 'allows creating a group without the reCAPTCHA' do
          expect(controller).not_to receive(:verify_recaptcha)

          expect do
            post :create, params: { group: { name: 'new_group', path: "new_group" } }
          end.to change { Group.count }.by(1)

          expect(response).to have_gitlab_http_status(:found)
        end
      end
    end
  end

  describe 'GET #index' do
    context 'as a user' do
      it 'redirects to Groups Dashboard' do
        sign_in(user)

        get :index

        expect(response).to redirect_to(dashboard_groups_path)
      end
    end

    context 'as a guest' do
      it 'redirects to Explore Groups' do
        get :index

        expect(response).to redirect_to(explore_groups_path)
      end
    end
  end

  describe 'GET #issues', :sidekiq_might_not_need_inline do
    let_it_be(:issue_1) { create(:issue, project: project, title: 'foo') }
    let_it_be(:issue_2) { create(:issue, project: project, title: 'bar') }

    before do
      create_list(:award_emoji, 3, awardable: issue_2)
      create_list(:award_emoji, 2, awardable: issue_1)
      create_list(:award_emoji, 2, :downvote, awardable: issue_2)

      sign_in(user)
    end

    context 'sorting by votes' do
      it 'sorts most popular issues' do
        get :issues, params: { id: group.to_param, sort: 'upvotes_desc' }
        expect(assigns(:issues)).to eq [issue_2, issue_1]
      end

      it 'sorts least popular issues' do
        get :issues, params: { id: group.to_param, sort: 'downvotes_desc' }
        expect(assigns(:issues)).to eq [issue_2, issue_1]
      end
    end

    context 'searching' do
      it 'works with popularity sort' do
        get :issues, params: { id: group.to_param, search: 'foo', sort: 'popularity' }

        expect(assigns(:issues)).to eq([issue_1])
      end

      it 'works with priority sort' do
        get :issues, params: { id: group.to_param, search: 'foo', sort: 'priority' }

        expect(assigns(:issues)).to eq([issue_1])
      end

      it 'works with label priority sort' do
        get :issues, params: { id: group.to_param, search: 'foo', sort: 'label_priority' }

        expect(assigns(:issues)).to eq([issue_1])
      end
    end
  end

  describe 'GET #merge_requests', :sidekiq_might_not_need_inline do
    let(:merge_request_1) { create(:merge_request, source_project: project) }
    let(:merge_request_2) { create(:merge_request, :simple, source_project: project) }

    before do
      create_list(:award_emoji, 3, awardable: merge_request_2)
      create_list(:award_emoji, 2, awardable: merge_request_1)
      create_list(:award_emoji, 2, :downvote, awardable: merge_request_2)

      sign_in(user)
    end

    context 'sorting by votes' do
      it 'sorts most popular merge requests' do
        get :merge_requests, params: { id: group.to_param, sort: 'upvotes_desc' }
        expect(assigns(:merge_requests)).to eq [merge_request_2, merge_request_1]
      end

      it 'sorts least popular merge requests' do
        get :merge_requests, params: { id: group.to_param, sort: 'downvotes_desc' }
        expect(assigns(:merge_requests)).to eq [merge_request_2, merge_request_1]
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'as another user' do
      it 'returns 404' do
        sign_in(create(:user))

        delete :destroy, params: { id: group.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'as the group owner' do
      before do
        sign_in(user)
      end

      it 'schedules a group destroy' do
        Sidekiq::Testing.fake! do
          expect { delete :destroy, params: { id: group.to_param } }.to change(GroupDestroyWorker.jobs, :size).by(1)
        end
      end

      it 'redirects to the root path' do
        delete :destroy, params: { id: group.to_param }

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PUT update' do
    before do
      sign_in(user)
    end

    it 'updates the path successfully' do
      post :update, params: { id: group.to_param, group: { path: 'new_path' } }

      expect(response).to have_gitlab_http_status(:found)
      expect(controller).to set_flash[:notice]
    end

    it 'does not update the path on error' do
      allow_any_instance_of(Group).to receive(:move_dir).and_raise(Gitlab::UpdatePathError)
      post :update, params: { id: group.to_param, group: { path: 'new_path' } }

      expect(assigns(:group).errors).not_to be_empty
      expect(assigns(:group).path).not_to eq('new_path')
    end

    it 'updates the project_creation_level successfully' do
      post :update, params: { id: group.to_param, group: { project_creation_level: ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS } }

      expect(response).to have_gitlab_http_status(:found)
      expect(group.reload.project_creation_level).to eq(::Gitlab::Access::MAINTAINER_PROJECT_ACCESS)
    end

    context 'updating default_branch_protection' do
      subject do
        put :update, params: { id: group.to_param, group: { default_branch_protection: ::Gitlab::Access::PROTECTION_DEV_CAN_MERGE } }
      end

      context 'for users who have the ability to update default_branch_protection' do
        it 'updates the attribute' do
          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(group.reload.default_branch_protection).to eq(::Gitlab::Access::PROTECTION_DEV_CAN_MERGE)
        end
      end

      context 'for users who do not have the ability to update default_branch_protection' do
        it 'does not update the attribute' do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :update_default_branch_protection, group) { false }

          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(group.reload.default_branch_protection).not_to eq(::Gitlab::Access::PROTECTION_DEV_CAN_MERGE)
        end
      end
    end

    context "updating default_branch_name" do
      let(:example_branch_name) { "example_branch_name" }

      subject(:update_action) do
        put :update,
          params: {
            id: group.to_param,
            group: { default_branch_name: example_branch_name }
          }
      end

      it "updates the attribute" do
        expect { subject }
          .to change { group.namespace_settings.reload.default_branch_name }
          .from(nil)
          .to(example_branch_name)

        expect(response).to have_gitlab_http_status(:found)
      end

      context "to empty string" do
        let(:example_branch_name) { '' }

        it "does not update the attribute" do
          subject

          expect(group.namespace_settings.reload.default_branch_name).not_to eq('')
        end
      end
    end

    context 'when there is a conflicting group path' do
      let!(:conflict_group) { create(:group, path: SecureRandom.hex(12) ) }
      let!(:old_name) { group.name }

      it 'does not render references to the conflicting group' do
        put :update, params: { id: group.to_param, group: { path: conflict_group.path } }

        expect(response).to have_gitlab_http_status(:ok)
        expect(group.reload.name).to eq(old_name)
        expect(response.body).not_to include(conflict_group.path)
      end
    end

    context 'when a project inside the group has container repositories' do
      before do
        stub_container_registry_config(enabled: true)
        stub_container_registry_tags(repository: /image/, tags: %w[rc1])
        create(:container_repository, project: project, name: :image)
      end

      it 'does allow the group to be renamed' do
        post :update, params: { id: group.to_param, group: { name: 'new_name' } }

        expect(controller).to set_flash[:notice]
        expect(response).to have_gitlab_http_status(:found)
        expect(group.reload.name).to eq('new_name')
      end

      it 'does not allow to path of the group to be changed' do
        post :update, params: { id: group.to_param, group: { path: 'new_path' } }

        expect(assigns(:group).errors[:base].first).to match(/Docker images in their Container Registry/)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  context "updating :resource_access_token_creation_allowed" do
    subject do
      put :update,
        params: {
          id: group.to_param,
          group: { resource_access_token_creation_allowed: false }
        }
    end

    context 'when user is a group owner' do
      before do
        group.add_owner(user)
        sign_in(user)
      end

      it "updates the attribute" do
        expect { subject }
            .to change { group.namespace_settings.reload.resource_access_token_creation_allowed }
            .from(true)
            .to(false)

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when not a group owner' do
      before do
        group.add_developer(user)
        sign_in(user)
      end

      it "does not update the attribute" do
        expect { subject }.not_to change { group.namespace_settings.reload.resource_access_token_creation_allowed }
      end
    end
  end

  describe 'updating :prevent_sharing_groups_outside_hierarchy' do
    subject do
      put :update,
        params: {
          id: group.to_param,
          group: { prevent_sharing_groups_outside_hierarchy: true }
        }
    end

    context 'when user is a group owner' do
      before do
        group.add_owner(user)
        sign_in(user)
      end

      it 'updates the attribute' do
        expect { subject }
            .to change { group.namespace_settings.reload.prevent_sharing_groups_outside_hierarchy }
            .from(false)
            .to(true)

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when not a group owner' do
      before do
        group.add_maintainer(user)
        sign_in(user)
      end

      it 'does not update the attribute' do
        expect { subject }.not_to change { group.namespace_settings.reload.prevent_sharing_groups_outside_hierarchy }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#ensure_canonical_path' do
    before do
      sign_in(user)
    end

    context 'for a GET request' do
      context 'when requesting groups at the root path' do
        before do
          allow(request).to receive(:original_fullpath).and_return("/#{group_full_path}")
          get :show, params: { id: group_full_path }
        end

        context 'when requesting the canonical path with different casing' do
          let(:group_full_path) { group.to_param.upcase }

          it 'redirects to the correct casing' do
            expect(response).to redirect_to(group)
            expect(controller).not_to set_flash[:notice]
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { group.redirect_routes.create!(path: 'old-path') }
          let(:group_full_path) { redirect_route.path }

          it 'redirects to the canonical path' do
            expect(response).to redirect_to(group)
            expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
          end

          context 'when the old group path is a substring of the scheme or host' do
            let(:redirect_route) { group.redirect_routes.create!(path: 'http') }

            it 'does not modify the requested host' do
              expect(response).to redirect_to(group)
              expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
            end
          end

          context 'when the old group path is substring of groups' do
            # I.e. /groups/oups should not become /grfoo/oups
            let(:redirect_route) { group.redirect_routes.create!(path: 'oups') }

            it 'does not modify the /groups part of the path' do
              expect(response).to redirect_to(group)
              expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
            end
          end
        end
      end

      context 'when requesting groups under the /groups path' do
        context 'when requesting the canonical path' do
          context 'non-show path' do
            context 'with exactly matching casing' do
              it 'does not redirect' do
                get :issues, params: { id: group.to_param }

                expect(response).not_to have_gitlab_http_status(:moved_permanently)
              end
            end

            context 'with different casing' do
              it 'redirects to the correct casing' do
                get :issues, params: { id: group.to_param.upcase }

                expect(response).to redirect_to(issues_group_path(group.to_param))
                expect(controller).not_to set_flash[:notice]
              end
            end
          end

          context 'show path' do
            context 'with exactly matching casing' do
              it 'does not redirect' do
                get :show, params: { id: group.to_param }

                expect(response).not_to have_gitlab_http_status(:moved_permanently)
              end
            end

            context 'with different casing' do
              it 'redirects to the correct casing at the root path' do
                get :show, params: { id: group.to_param.upcase }

                expect(response).to redirect_to(group)
                expect(controller).not_to set_flash[:notice]
              end
            end
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { group.redirect_routes.create!(path: 'old-path') }

          it 'redirects to the canonical path' do
            get :issues, params: { id: redirect_route.path }

            expect(response).to redirect_to(issues_group_path(group.to_param))
            expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
          end

          context 'when the old group path is a substring of the scheme or host' do
            let(:redirect_route) { group.redirect_routes.create!(path: 'http') }

            it 'does not modify the requested host' do
              get :issues, params: { id: redirect_route.path }

              expect(response).to redirect_to(issues_group_path(group.to_param))
              expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
            end
          end

          context 'when the old group path is substring of groups' do
            # I.e. /groups/oups should not become /grfoo/oups
            let(:redirect_route) { group.redirect_routes.create!(path: 'oups') }

            it 'does not modify the /groups part of the path' do
              get :issues, params: { id: redirect_route.path }

              expect(response).to redirect_to(issues_group_path(group.to_param))
              expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
            end
          end

          context 'when the old group path is substring of groups plus the new path' do
            # I.e. /groups/oups/oup should not become /grfoos
            let(:redirect_route) { group.redirect_routes.create!(path: 'oups/oup') }

            it 'does not modify the /groups part of the path' do
              get :issues, params: { id: redirect_route.path }

              expect(response).to redirect_to(issues_group_path(group.to_param))
              expect(controller).to set_flash[:notice].to(group_moved_message(redirect_route, group))
            end
          end
        end
      end

      context 'for a POST request' do
        context 'when requesting the canonical path with different casing' do
          it 'does not 404' do
            post :update, params: { id: group.to_param.upcase, group: { path: 'new_path' } }

            expect(response).not_to have_gitlab_http_status(:not_found)
          end

          it 'does not redirect to the correct casing' do
            post :update, params: { id: group.to_param.upcase, group: { path: 'new_path' } }

            expect(response).not_to have_gitlab_http_status(:moved_permanently)
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { group.redirect_routes.create!(path: 'old-path') }

          it 'returns not found' do
            post :update, params: { id: redirect_route.path, group: { path: 'new_path' } }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'for a DELETE request' do
        context 'when requesting the canonical path with different casing' do
          it 'does not 404' do
            delete :destroy, params: { id: group.to_param.upcase }

            expect(response).not_to have_gitlab_http_status(:not_found)
          end

          it 'does not redirect to the correct casing' do
            delete :destroy, params: { id: group.to_param.upcase }

            expect(response).not_to have_gitlab_http_status(:moved_permanently)
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { group.redirect_routes.create!(path: 'old-path') }

          it 'returns not found' do
            delete :destroy, params: { id: redirect_route.path }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    def group_moved_message(redirect_route, group)
      "Group '#{redirect_route.path}' was moved to '#{group.full_path}'. Please update any links and bookmarks that may still have the old path."
    end
  end

  describe 'PUT transfer' do
    before do
      sign_in(user)
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
        allow_any_instance_of(::Groups::TransferService).to receive(:proceed_to_transfer).and_raise(Gitlab::UpdatePathError, 'namespace directory cannot be moved')

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
        expect(controller).to set_flash[:alert].to match(/Docker images in their Container Registry/)
        expect(response).to redirect_to(edit_group_path(group))
      end
    end
  end

  describe 'POST #export' do
    let(:admin) { create(:admin) }

    before do
      enable_admin_mode!(admin)
    end

    context 'when the group export feature flag is not enabled' do
      before do
        sign_in(admin)
        stub_feature_flags(group_import_export: false)
      end

      it 'returns a not found error' do
        post :export, params: { id: group.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user does not have permission to export the group' do
      before do
        sign_in(guest)
      end

      it 'returns an error' do
        post :export, params: { id: group.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when supplied valid params' do
      before do
        sign_in(admin)
      end

      it 'triggers the export job' do
        expect(GroupExportWorker).to receive(:perform_async).with(admin.id, group.id, {})

        post :export, params: { id: group.to_param }
      end

      it 'redirects to the edit page' do
        post :export, params: { id: group.to_param }

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when the endpoint receives requests above the rate limit' do
      before do
        sign_in(admin)

        allow(Gitlab::ApplicationRateLimiter)
          .to receive(:increment)
          .and_return(Gitlab::ApplicationRateLimiter.rate_limits[:group_export][:threshold].call + 1)
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
        create(:import_export_upload, group: group, export_file: export_file)
      end

      it 'sends the file' do
        get :download_export, params: { id: group.to_param }

        expect(response.body).to eq export_file.tempfile.read
      end
    end

    context 'when the file is no longer present on disk' do
      before do
        sign_in(admin)

        create(:import_export_upload, group: group, export_file: export_file)
        group.export_file.file.delete
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

    context 'when the group export feature flag is not enabled' do
      before do
        sign_in(admin)
        stub_feature_flags(group_import_export: false)
      end

      it 'returns a not found error' do
        post :export, params: { id: group.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
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

        allow(Gitlab::ApplicationRateLimiter)
          .to receive(:increment)
          .and_return(Gitlab::ApplicationRateLimiter.rate_limits[:group_download_export][:threshold].call + 1)
      end

      it 'throttles the endpoint' do
        get :download_export, params: { id: group.to_param }

        expect(response.body).to eq('This endpoint has been requested too many times. Try again later.')
        expect(response).to have_gitlab_http_status :too_many_requests
      end
    end
  end

  context 'token authentication' do
    it_behaves_like 'authenticates sessionless user', :show, :atom, public: true do
      before do
        default_params.merge!(id: group)
      end
    end

    it_behaves_like 'authenticates sessionless user', :issues, :atom, public: true do
      before do
        default_params.merge!(id: group, author_id: user.id)
      end
    end

    it_behaves_like 'authenticates sessionless user', :issues_calendar, :ics, public: true do
      before do
        default_params.merge!(id: group)
      end
    end
  end

  describe 'external authorization' do
    before do
      group.add_owner(user)
      sign_in(user)
    end

    context 'with external authorization service enabled' do
      before do
        enable_external_authorization_service_check
      end

      describe 'GET #show' do
        it 'is successful' do
          get :show, params: { id: group.to_param }

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'does not allow other formats' do
          get :show, params: { id: group.to_param }, format: :atom

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      describe 'GET #edit' do
        it 'is successful' do
          get :edit, params: { id: group.to_param }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      describe 'GET #new' do
        it 'is successful' do
          get :new

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      describe 'GET #index' do
        it 'is successful' do
          get :index

          # Redirects to the dashboard
          expect(response).to have_gitlab_http_status(:found)
        end
      end

      describe 'POST #create' do
        it 'creates a group' do
          expect do
            post :create, params: { group: { name: 'a name', path: 'a-name' } }
          end.to change { Group.count }.by(1)
        end
      end

      describe 'PUT #update' do
        it 'updates a group' do
          expect do
            put :update, params: { id: group.to_param, group: { name: 'world' } }
          end.to change { group.reload.name }
        end

        context "malicious group name" do
          subject { put :update, params: { id: group.to_param, group: { name: "<script>alert('Attack!');</script>" } } }

          it { is_expected.to render_template(:edit) }

          it 'does not update name' do
            expect { subject }.not_to change { group.reload.name }
          end
        end
      end

      describe 'DELETE #destroy' do
        it 'deletes the group' do
          delete :destroy, params: { id: group.to_param }

          expect(response).to have_gitlab_http_status(:found)
        end
      end
    end

    describe 'GET #activity' do
      subject { get :activity, params: { id: group.to_param } }

      it_behaves_like 'disabled when using an external authorization service'
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

    describe 'GET #issues' do
      subject { get :issues, params: { id: group.to_param } }

      it_behaves_like 'disabled when using an external authorization service'
    end

    describe 'GET #merge_requests' do
      subject { get :merge_requests, params: { id: group.to_param } }

      it_behaves_like 'disabled when using an external authorization service'
    end
  end

  describe 'GET #unfoldered_environment_names' do
    it 'shows the environment names of a public project to an anonymous user' do
      public_project = create(:project, :public, namespace: group)

      create(:environment, project: public_project, name: 'foo')

      get(
        :unfoldered_environment_names,
        params: { id: group, format: :json }
      )

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(%w[foo])
    end

    it 'does not show environment names of private projects to anonymous users' do
      create(:environment, project: project, name: 'foo')

      get(
        :unfoldered_environment_names,
        params: { id: group, format: :json }
      )

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_empty
    end

    it 'shows environment names of a private project to a group member' do
      create(:environment, project: project, name: 'foo')
      sign_in(developer)

      get(
        :unfoldered_environment_names,
        params: { id: group, format: :json }
      )

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(%w[foo])
    end

    it 'does not show environment names of private projects to a logged-in non-member' do
      alice = create(:user)

      create(:environment, project: project, name: 'foo')
      sign_in(alice)

      get(
        :unfoldered_environment_names,
        params: { id: group, format: :json }
      )

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_empty
    end
  end
end
