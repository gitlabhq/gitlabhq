require 'spec_helper'

feature 'Projects members', feature: true do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }

  background do
    group.add_owner(user)
    login_as(user)
    visit namespace_project_project_members_path(project.namespace, project)
  end

  it 'shows group members in list' do
    expect(page).to have_selector('.group_member')

    page.within first('.content-list .member') do
      expect(page).to have_content(group.name)
    end
  end
end
