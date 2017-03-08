require 'spec_helper'

feature 'Projects > Members > Member is removed from project', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  background do
    project.team << [user, :master]
    login_as(user)
    visit namespace_project_project_members_path(project.namespace, project)
  end

  scenario 'user is removed from project' do
    within(".project_member") { find(".btn-remove").click }

    expect(project.users.exists?(user.id)).to be_falsey
  end

  context 'when the user has been specifically allowed to access a protected branch' do
    let(:other_user) { create(:user) }
    let!(:matching_protected_branch) { create(:protected_branch, authorize_user_to_push: user, authorize_user_to_merge: user, project: project) }
    let!(:non_matching_protected_branch) { create(:protected_branch, authorize_user_to_push: other_user, authorize_user_to_merge: other_user, project: project) }

    scenario 'user leaves project' do
      within(".project_member") { find(".btn-remove").click }

      expect(project.users.exists?(user.id)).to be_falsey
      expect(matching_protected_branch.push_access_levels.where(user: user)).not_to exist
      expect(matching_protected_branch.merge_access_levels.where(user: user)).not_to exist
      expect(non_matching_protected_branch.push_access_levels.where(user: other_user)).to exist
      expect(non_matching_protected_branch.merge_access_levels.where(user: other_user)).to exist
    end
  end
end
