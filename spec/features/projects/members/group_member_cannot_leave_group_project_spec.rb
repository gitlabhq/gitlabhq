require 'spec_helper'

feature 'Projects > Members > Group member cannot leave group project', feature: true do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }

  background do
    group.add_developer(user)
    login_as(user)
    visit namespace_project_path(project.namespace, project)
  end

  scenario 'user does not see a "Leave project" link' do
    expect(page).not_to have_content 'Leave Project'
  end
end
