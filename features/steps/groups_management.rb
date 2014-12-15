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
    click_link 'Settings'
    click_link 'Members'
  end

  step 'I can control user membership' do
    page.should have_link 'New project member'
    page.should have_link 'Import members'
    page.should have_selector '#project_member_access_level', text: 'Master'
  end

  step 'I reload "Open" project members page' do
    click_link 'Members'
  end

  step 'I go to group settings page' do
    click_link 'sidebar-groups-tab'
    click_link 'Sourcing'
    click_link 'Settings'
  end

  step 'I enable membership lock' do
    check 'group_membership_lock'
    click_button 'Save group'
  end

  step 'I go to project settings' do
    @project = Project.find_by(name: "Open")
    click_link 'Projects'

    link = "/#{@project.path_with_namespace}/team"
    find(:xpath, "//a[@href=\"#{link}\"]").click
  end

  step 'I cannot control user membership from project page' do
    page.should_not have_link 'New project member'
    page.should_not have_link 'Import members'
    page.should_not have_selector '#project_member_access_level', text: 'Master'
  end
end
