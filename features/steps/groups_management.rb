class Spinach::Features::GroupsManagement < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedGroup
  include SharedUser
  include Select2Helper

  step '"Open" is in group "Sourcing"' do
    @group = Group.find_by(name: "Sourcing")
    @project ||= create(:project, name: "Open", namespace: @group)
  end

  step '"Mary Jane" has master access for project "Open"' do
    @user = User.find_by(name: "Mary Jane") || create(:user, name: "Mary Jane")
    @project = Project.find_by(name: "Open")
    @project.team << [@user, :master]
  end

  step "Group membership lock is enabled" do
    @group = Group.find_by(name: "Sourcing")
    @group.update_attributes(membership_lock: true)
  end

  step 'I go to "Open" project members page' do
    click_link 'Sourcing / Open'
    click_link 'Members'
  end

  step 'I can control user membership' do
    expect(page).to have_link 'Import members'
    expect(page).to have_selector '.project-access-select'
  end

  step 'I reload "Open" project members page' do
    visit root_path
    click_link 'Sourcing / Open'
    page.within('.project-settings-dropdown') do
      click_link 'Members'
    end
  end

  step 'I go to group settings page' do
    visit dashboard_groups_path
    click_link 'Sourcing'
    click_link 'Edit Group'
  end

  step 'I enable membership lock' do
    check 'group_membership_lock'
    click_button 'Save group'
  end

  step 'I go to project settings' do
    @project = Project.find_by(name: "Open")
    page.within '.layout-nav' do
      click_link 'Projects'
    end

    link = "/#{@project.path_with_namespace}/project_members"
    find(:xpath, "//a[@href=\"#{link}\"]").click
  end

  step 'I cannot control user membership from project page' do
    expect(page).not_to have_button 'Add members'
    expect(page).not_to have_link 'Import members'
  end
end
