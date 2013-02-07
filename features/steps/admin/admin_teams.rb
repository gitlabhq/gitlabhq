class AdminTeams < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedActiveTab
  include SharedAdmin

  And 'I have own project' do
    create :project
  end

  And 'Create gitlab user "John"' do
    @user = create(:user, :name => "John")
  end

  And 'I click new team link' do
    click_link "New Team"
  end

  And 'submit form with new team info' do
    fill_in 'user_team_name', with: 'gitlab'
    click_button 'Create team'
  end

  Then 'I should be redirected to team page' do
    current_path.should == admin_team_path(UserTeam.last)
  end

  And 'I should see newly created team' do
    page.should have_content "Team: gitlab"
  end

  When 'I visit admin teams page' do
    visit admin_teams_path
  end

  When 'I have clean "HardCoders" team' do
    @team = create :user_team, name: "HardCoders", owner: current_user
  end

  And 'I visit "HardCoders" team page' do
    visit admin_team_path(UserTeam.find_by_name("HardCoders"))
  end

  Then 'I should see only me in members table' do
    members_list = find("#members_list .member")
    members_list.should have_content(current_user.name)
    members_list.should have_content(current_user.email)
  end

  When 'I select user "John" from user list as "Developer"' do
    @user ||= User.find_by_name("John")
    within "#team_members" do
      select @user.name, :from => "user_ids"
      select "Developer", :from => "default_project_access"
    end
  end

  And 'submit form with new team member info' do
    click_button 'add_members_to_team'
  end

  Then 'I should see "John" in teams members list as "Developer"' do
    @user ||= User.find_by_name("John")
    find_in_list("#members_list .member", @user).must_equal true
  end

  When 'I visit "John" user admin page' do
    pending 'step not implemented'
  end

  Then 'I should see "HardCoders" team in teams table' do
    pending 'step not implemented'
  end

  When 'I have "HardCoders" team with "John" member with "Developer" role' do
    @team = create :user_team, name: "HardCoders", owner: current_user
    @user ||= User.find_by_name("John")
    @team.add_member(@user, UserTeam.access_roles["Developer"], group_admin: false)
  end

  When 'I have "Shop" project' do
    @project = create :project, name: "Shop"
  end

  Then 'I should see empty projects table' do
    page.has_no_css?("#projects_list").must_equal true
  end

  When 'I select project "Shop" with max access "Reporter"' do
    @project ||= Project.find_by_name("Shop")
    within "#assign_projects" do
      select @project.name, :from => "project_ids"
      select "Reporter", :from => "greatest_project_access"
    end

  end

  And 'submit form with new team project info' do
    click_button 'assign_projects_to_team'
  end

  Then 'I should see "Shop" project in projects list' do
    project = Project.find_by_name("Shop")
    find_in_list("#projects_list .project", project).must_equal true
  end

  When 'I visit "Shop" project admin page' do
    project = Project.find_by_name("Shop")
    visit admin_project_path(project)
  end

  And '"HardCoders" team assigned to "Shop" project with "Developer" max role access' do
    @team = UserTeam.find_by_name("HardCoders")
    @project = create :project, name: "Shop"
    @team.assign_to_project(@project, UserTeam.access_roles["Developer"])
  end

  When 'I have gitlab user "Jimm"' do
    create :user, name: "Jimm"
  end

  Then 'I should see members table without "Jimm" member' do
    user = User.find_by_name("Jimm")
    find_in_list("#members_list .member", user).must_equal false
  end

  When 'I select user "Jimm" ub team members list as "Master"' do
    user = User.find_by_name("Jimm")
    within "#team_members" do
      select user.name, :from => "user_ids"
      select "Developer", :from => "default_project_access"
    end
  end

  Then 'I should see "Jimm" in teams members list as "Master"' do
    user = User.find_by_name("Jimm")
    find_in_list("#members_list .member", user).must_equal true
  end

  Given 'I have users team "HardCoders"' do
    @team = create :user_team, name: "HardCoders"
  end

  And 'gitlab user "John" is a member "HardCoders" team' do
    @team = UserTeam.find_by_name("HardCoders")
    @user = User.find_by_name("John")
    @user = create :user, name: "John" unless @user
    @team.add_member(@user, UserTeam.access_roles["Master"], group_admin: false)
  end

  And 'gitlab user "Jimm" is a member "HardCoders" team' do
    @team = UserTeam.find_by_name("HardCoders")
    @user = User.find_by_name("Jimm")
    @user = create :user, name: "Jimm" unless @user
    @team.add_member(@user, UserTeam.access_roles["Master"], group_admin: false)
  end

  And '"HardCoders" team is assigned to "Shop" project' do
    @team = UserTeam.find_by_name("HardCoders")
    @project = create :project, name: "Shop"
    @team.assign_to_project(@project, UserTeam.access_roles["Developer"])
  end

  When 'I visit "HardCoders" team admin page' do
    visit admin_team_path(UserTeam.find_by_name("HardCoders"))
  end

  Then 'I shoould see "John" in members list' do
    user = User.find_by_name("John")
    find_in_list("#members_list .member", user).must_equal true
  end

  And 'I should see "Jimm" in members list' do
    user = User.find_by_name("Jimm")
    find_in_list("#members_list .member", user).must_equal true
  end

  And 'I should see "Shop" in projects list' do
    project = Project.find_by_name("Shop")
    find_in_list("#projects_list .project", project).must_equal true
  end

  When 'I click on remove "Jimm" user link' do
    user = User.find_by_name("Jimm")
    click_link "remove_member_#{user.id}"
  end

  Then 'I should be redirected to "HardCoders" team admin page' do
    current_path.should == admin_team_path(UserTeam.find_by_name("HardCoders"))
  end

  And 'I should not to see "Jimm" user in members list' do
    user = User.find_by_name("Jimm")
    find_in_list("#members_list .member", user).must_equal false
  end

  When 'I click on "Relegate" link on "Shop" project' do
    project = Project.find_by_name("Shop")
    click_link "relegate_project_#{project.id}"
  end

  Then 'I should see projects liston team page without "Shop" project' do
    project = Project.find_by_name("Shop")
    find_in_list("#projects_list .project", project).must_equal false
  end

  Then 'I should see "John" user with role "Reporter" in team table' do
    user = User.find_by_name("John")
    find_in_list(".team_members", user).must_equal true
  end

  When 'I click to "Add members" link' do
    click_link "Add members"
  end

  When 'I click to "Add projects" link' do
    click_link "Add projects"
  end

  protected

  def current_team
    @team ||= Team.first
  end

  def find_in_list(selector, item)
    members_list = all(selector)
    entered = false
    members_list.each do |member_item|
      entered = true if member_item.has_content?(item.name)
    end
    entered
  end
end
