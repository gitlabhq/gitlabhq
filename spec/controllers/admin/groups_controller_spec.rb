# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::GroupsController do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'DELETE #destroy' do
    it 'schedules a group destroy' do
      Sidekiq::Testing.fake! do
        expect { delete :destroy, params: { id: project.group.path } }.to change(GroupDestroyWorker.jobs, :size).by(1)
      end
    end

    it 'redirects to the admin group path' do
      delete :destroy, params: { id: project.group.path }

      expect(response).to redirect_to(admin_groups_path)
    end
  end

  describe 'POST #create' do
    it 'creates group' do
      expect do
        post :create, params: { group: {  path: 'test', name: 'test' } }
      end.to change { Group.count }.by(1)
    end

    it 'creates namespace_settings for group' do
      expect do
        post :create, params: { group: {  path: 'test', name: 'test' } }
      end.to change { NamespaceSetting.count }.by(1)
    end

    it 'creates admin_note for group' do
      expect do
        post :create, params: { group: {  path: 'test', name: 'test', admin_note_attributes: { note: 'test' } } }
      end.to change { Namespace::AdminNote.count }.by(1)
    end
  end

  describe 'PUT #members_update' do
    let_it_be(:group_user) { create(:user) }

    it 'adds user to members', :aggregate_failures, :snowplow do
      put :members_update, params: {
                             id: group,
                             user_ids: group_user.id,
                             access_level: Gitlab::Access::GUEST
                           }

      expect(controller).to set_flash.to 'Users were successfully added.'
      expect(response).to redirect_to(admin_group_path(group))
      expect(group.users).to include group_user
      expect_snowplow_event(
        category: 'Members::CreateService',
        action: 'create_member',
        label: 'admin-group-page',
        property: 'existing_user',
        user: admin
      )
    end

    it 'can add unlimited members', :aggregate_failures do
      put :members_update, params: {
                             id: group,
                             user_ids: 1.upto(1000).to_a.join(','),
                             access_level: Gitlab::Access::GUEST
                           }

      expect(controller).to set_flash.to 'Users were successfully added.'
      expect(response).to redirect_to(admin_group_path(group))
    end

    it 'adds no user to members', :aggregate_failures do
      put :members_update, params: {
                             id: group,
                             user_ids: '',
                             access_level: Gitlab::Access::GUEST
                           }

      expect(controller).to set_flash.to 'No users specified.'
      expect(response).to redirect_to(admin_group_path(group))
      expect(group.users).not_to include group_user
    end

    it 'updates the project_creation_level successfully' do
      expect do
        post :update, params: { id: group.to_param, group: { project_creation_level: ::Gitlab::Access::NO_ONE_PROJECT_ACCESS } }
      end.to change { group.reload.project_creation_level }.to(::Gitlab::Access::NO_ONE_PROJECT_ACCESS)
    end

    it 'updates the subgroup_creation_level successfully' do
      expect do
        post :update,
             params: { id: group.to_param,
                       group: { subgroup_creation_level: ::Gitlab::Access::OWNER_SUBGROUP_ACCESS } }
      end.to change { group.reload.subgroup_creation_level }.to(::Gitlab::Access::OWNER_SUBGROUP_ACCESS)
    end
  end
end
