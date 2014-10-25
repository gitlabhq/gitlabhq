class Spinach::Features::AdminGroups < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedUser
  include SharedActiveTab
  include Select2Helper

  When 'I visit admin group page' do
    visit admin_group_path(current_group)
  end

  When 'I click new group link' do
    click_link "New Group"
  end

  step 'I have group with projects' do
    @group   = create(:group)
    @project = create(:project, group: @group)
    @event   = create(:closed_issue_event, project: @project)

    @project.team << [current_user, :master]
  end

  step 'submit form with new group info' do
    fill_in 'group_name', with: 'gitlab'
    fill_in 'group_description', with: 'Group description'
    click_button "Create group"
  end

  step 'I should see newly created group' do
    page.should have_content "Group: gitlab"
    page.should have_content "Group description"
  end

  step 'I should be redirected to group page' do
    current_path.should == admin_group_path(Group.last)
  end

  When 'I select user "John Doe" from user list as "Reporter"' do
    select2(user_john.id, from: "#user_ids", multiple: true)
    within "#new_team_member" do
      select "Reporter", from: "access_level"
    end
    click_button "Add users into group"
  end

  step 'I should see "John Doe" in team list in every project as "Reporter"' do
    within ".group-users-list" do
      page.should have_content "John Doe"
      page.should have_content "Reporter"
    end
  end

  step 'I should be all groups' do
    Group.all.each do |group|
      page.should have_content group.name
    end
  end

  step 'we have user "John Doe" in group' do
    current_group.add_user(user_john, Gitlab::Access::REPORTER)
  end

  step 'I remove user "John Doe" from group' do
    within "#user_#{user_john.id}" do
      click_link 'Remove user from group'
    end
  end

  step 'I should not see "John Doe" in team list' do
    within ".group-users-list" do
      page.should_not have_content "John Doe"
    end
  end

  protected

  def current_group
    @group ||= Group.first
  end

  def user_john
    @user_john ||= User.find_by(name: "John Doe")
  end
end
