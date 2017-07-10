require 'spec_helper'

feature 'Projects > Members > Member leaves project', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  background do
    project.team << [user, :developer]
    sign_in(user)
    visit project_path(project)
  end

  scenario 'user leaves project' do
    click_link 'Leave project'

    expect(current_path).to eq(dashboard_projects_path)
    expect(project.users.exists?(user.id)).to be_falsey
  end

  context 'when the user has been specifically allowed to access a protected branch' do
    let(:other_user) { create(:user) }
    let!(:matching_protected_branch) { create(:protected_branch, authorize_user_to_push: user, authorize_user_to_merge: user, project: project) }
    let!(:non_matching_protected_branch) { create(:protected_branch, authorize_user_to_push: other_user, authorize_user_to_merge: other_user, project: project) }

    context 'user leaves project' do
      scenario "removes the user's branch permissions" do
        click_link 'Leave project'

        expect(current_path).to eq(dashboard_projects_path)
        expect(matching_protected_branch.push_access_levels.where(user: user)).not_to exist
        expect(matching_protected_branch.merge_access_levels.where(user: user)).not_to exist
        expect(non_matching_protected_branch.push_access_levels.where(user: other_user)).to exist
        expect(non_matching_protected_branch.merge_access_levels.where(user: other_user)).to exist
      end
    end
  end
end
