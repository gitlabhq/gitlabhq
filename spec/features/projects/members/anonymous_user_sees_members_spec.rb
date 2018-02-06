require 'spec_helper'

feature 'Projects > Members > Anonymous user sees members' do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public) }

  background do
    project.add_master(user)
    create(:project_group_link, project: project, group: group)
  end

  scenario "anonymous user visits the project's members page and sees the list of members" do
    visit project_project_members_path(project)

    expect(current_path).to eq(
      project_project_members_path(project))
    expect(page).to have_content(user.name)
  end
end
