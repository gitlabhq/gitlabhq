require 'spec_helper'

feature 'New project member dropdown', feature: true, js: true do
  include WaitForAjax

  let(:user)    { create(:user) }
  let!(:user2)  { create(:user) }
  let!(:group)  { create(:group) }
  let!(:group2) { create(:group) }
  let(:project) { create(:project) }

  background do
    project.team << [user, :master]
    login_as(user)
    visit namespace_project_project_members_path(project.namespace, project)
  end

  it 'displays list of groups and users' do
    open_dropdown

    page.within '.dropdown-members' do
      expect(page).to have_content(user2.name)
      expect(page).to have_content(group.name)
      expect(page).to have_content(group2.name)
    end
  end

  it 'adds a user' do
    open_dropdown

    page.within '.dropdown-members' do
      click_link user2.name
    end

    expect(find('#js-members-input').value).to eq(user2.name)

    click_button 'Add to project'
    expect(page).to have_selector('.project_member', count: 2)
  end

  it 'adds a group' do
    open_dropdown

    page.within '.dropdown-members' do
      click_link group.name
    end

    expect(find('#js-members-input').value).to eq group.name

    click_button 'Add to project'
    expect(page).to have_selector('.group_member', count: 1)
  end

  it 'adds multiple groups' do
    open_dropdown

    page.within '.dropdown-members' do
      click_link group.name
      click_link group2.name
    end

    expect(find('#js-members-input').value).to eq("#{group.name},#{group2.name}")

    click_button 'Add to project'
    expect(page).to have_selector('.group_member', count: 2)
  end

  it 'adds a user & a group' do
    open_dropdown

    page.within '.dropdown-members' do
      click_link user2.name
      click_link group.name
    end

    expect(find('#js-members-input').value).to eq("#{user2.name},#{group.name}")

    click_button 'Add to project'
    expect(page).to have_selector('.project_member', count: 2)
    expect(page).to have_selector('.group_member', count: 1)
  end

  def open_dropdown
    find('#js-members-input').click
    wait_for_ajax
  end
end
