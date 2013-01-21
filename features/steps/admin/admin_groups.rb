class AdminGroups < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedActiveTab

  When 'I visit admin group page' do
    visit admin_group_path(current_group)
  end

  When 'I click new group link' do
    click_link "New Group"
  end

  And 'I have group with projects' do
    @group   = create(:group)
    @project = create(:project, group: @group)
    @event   = create(:closed_issue_event, project: @project)

    @project.team << [current_user, :master]
  end

  And 'Create gitlab user "John"' do
    create(:user, :name => "John")
  end

  And 'submit form with new group info' do
    fill_in 'group_name', :with => 'gitlab'
    click_button "Create group"
  end

  Then 'I should see newly created group' do
    page.should have_content "Group: gitlab"
  end

  Then 'I should be redirected to group page' do
    current_path.should == admin_group_path(Group.last)
  end

  When 'I select user "John" from user list as "Reporter"' do
    user = User.find_by_name("John")
    within "#new_team_member" do
      select user.name, :from => "user_ids"
      select "Reporter", :from => "project_access"
    end
    click_button "Add user to projects in group"
  end

  Then 'I should see "John" in team list in every project as "Reporter"' do
    user = User.find_by_name("John")
    projects_with_access = find(".user_#{user.id} .projects_access")
    projects_with_access.should have_link("Reporter")
  end

  protected

  def current_group
    @group ||= Group.first
  end
end
