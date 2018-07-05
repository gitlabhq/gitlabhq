require 'spec_helper'

describe 'Projects > Members > Member leaves project' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)
    sign_in(user)
    visit project_path(project)
  end

  context 'when the user has been specifically allowed to access a protected branch' do
    let(:other_user) { create(:user) }
    let!(:matching_protected_branch) { create(:protected_branch, authorize_user_to_push: user, authorize_user_to_merge: user, project: project) }
    let!(:non_matching_protected_branch) { create(:protected_branch, authorize_user_to_push: other_user, authorize_user_to_merge: other_user, project: project) }

    context 'user leaves project' do
      it "removes the user's branch permissions" do
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
