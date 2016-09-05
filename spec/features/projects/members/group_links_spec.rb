require 'spec_helper'

feature 'Projects > Members > Anonymous user sees members', feature: true, js: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:empty_project, :public) }

  background do
    project.team << [user, :master]
    @group_link = create(:project_group_link, project: project, group: group)

    login_as(user)
    visit namespace_project_project_members_path(project.namespace, project)
  end

  it 'updates group access level' do
    select 'Guest', from: "member_access_level_#{group.id}"
    wait_for_ajax

    visit namespace_project_project_members_path(project.namespace, project)

    expect(page).to have_select("member_access_level_#{group.id}", selected: 'Guest')
  end

  it 'updates expiry date' do
    tomorrow = Date.today + 3

    fill_in "member_expires_at_#{group.id}", with: tomorrow.strftime("%F")
    wait_for_ajax

    page.within(first('li.member')) do
      expect(page).to have_content('Expires in 3 days')
    end
  end
end
