require 'spec_helper'

describe Admin::GroupsController do
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'DELETE #destroy' do
    it 'schedules a group destroy' do
      Sidekiq::Testing.fake! do
        expect { delete :destroy, id: project.group.path }.to change(GroupDestroyWorker.jobs, :size).by(1)
      end
    end

    it 'redirects to the admin group path' do
      delete :destroy, id: project.group.path

      expect(response).to redirect_to(admin_groups_path)
    end
  end

  describe 'PUT #members_update' do
    let(:group_user) { create(:user) }

    it 'adds user to members' do
      put :members_update, id: group,
                           user_ids: group_user.id,
                           access_level: Gitlab::Access::GUEST

      expect(response).to set_flash.to 'Users were successfully added.'
      expect(response).to redirect_to(admin_group_path(group))
      expect(group.users).to include group_user
    end

    it 'can add unlimited members' do
      put :members_update, id: group,
                           user_ids: 1.upto(1000).to_a.join(','),
                           access_level: Gitlab::Access::GUEST

      expect(response).to set_flash.to 'Users were successfully added.'
      expect(response).to redirect_to(admin_group_path(group))
    end

    it 'adds no user to members' do
      put :members_update, id: group,
                           user_ids: '',
                           access_level: Gitlab::Access::GUEST

      expect(response).to set_flash.to 'No users specified.'
      expect(response).to redirect_to(admin_group_path(group))
      expect(group.users).not_to include group_user
    end
  end
end
