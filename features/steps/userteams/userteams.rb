class Userteams < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

    When 'I do not have teams with me' do
      UserTeam.with_member(current_user).destroy_all
    end

    Then 'I should see dashboard page without teams info block' do
      page.has_no_css?(".teams-box").must_equal true
    end

    When 'I have teams with my membership' do
      team = create :user_team, owner: current_user
      team.add_member(current_user, UserTeam.access_roles["Master"], true)
    end

    Then 'I should see dashboard page with teams information block' do
      page.should have_css(".teams-box")
    end

    When 'exist user teams' do
      team = create :user_team
      team.add_member(current_user, UserTeam.access_roles["Master"], true)
    end

    And 'I click on "All teams" link' do
      click_link("All Teams")
    end

    Then 'I should see "All teams" page' do
      current_path.should == teams_path
    end

    And 'I should see exist teams in teams list' do
      team = UserTeam.last
      find_in_list(".teams_list tr", team).must_equal true
    end

    When 'I click to "New team" link' do
      click_link("New Team")
    end

    And 'I submit form with new team info' do
      fill_in 'name', with: 'gitlab'
      click_button 'Create team'
    end

    Then 'I should be redirected to new team page' do
      team = UserTeam.last
      current_path.should == team_path(team)
    end

    When 'I have teams with projects and members' do
      team = create :user_team, owner: current_user
      @project = create :project
      team.add_member(current_user, UserTeam.access_roles["Master"], true)
      team.assign_to_project(@project, UserTeam.access_roles["Master"])
      @event = create(:closed_issue_event, project: @project)
    end

    When 'I visit team page' do
      visit team_path(UserTeam.last)
    end

    Then 'I should see projects list' do
      page.should have_css(".projects_box")
      projects_box = find(".projects_box")
      projects_box.should have_content(@project.name)
    end

    And 'project from team has issues assigned to me' do
      team = UserTeam.last
      team.projects.each do |project|
        project.issues << create(:issue, assignee: current_user)
      end
    end

    When 'I visit team issues page' do
      team = UserTeam.last
      visit issues_team_path(team)
    end

    Then 'I should see issues from this team assigned to me' do
      team = UserTeam.last
      team.projects.each do |project|
        project.issues.assigned(current_user).each do |issue|
          page.should have_content issue.title
        end
      end
    end

    Given 'I have team with projects and members' do
      team = create :user_team, owner: current_user
      project = create :project
      user = create :user
      team.add_member(current_user, UserTeam.access_roles["Master"], true)
      team.add_member(user, UserTeam.access_roles["Developer"], false)
      team.assign_to_project(project, UserTeam.access_roles["Master"])
    end

    Given 'project from team has issues assigned to teams members' do
      team = UserTeam.last
      team.projects.each do |project|
        team.members.each do |member|
          project.issues << create(:issue, assignee: member)
        end
      end
    end

    Then 'I should see issues from this team assigned to teams members' do
      team = UserTeam.last
      team.projects.each do |project|
        team.members.each do |member|
          project.issues.assigned(member).each do |issue|
            page.should have_content issue.title
          end
        end
      end
    end

    Given 'project from team has merge requests assigned to me' do
      team = UserTeam.last
      team.projects.each do |project|
        team.members.each do |member|
          3.times { project.merge_requests << create(:merge_request, assignee: member) }
        end
      end
    end

    When 'I visit team merge requests page' do
      team = UserTeam.last
      visit merge_requests_team_path(team)
    end

    Then 'I should see merge requests from this team assigned to me' do
      team = UserTeam.last
      team.projects.each do |project|
        team.members.each do |member|
          project.issues.assigned(member).each do |merge_request|
            page.should have_content merge_request.title
          end
        end
      end
    end

    Given 'project from team has merge requests assigned to team members' do
      team = UserTeam.last
      team.projects.each do |project|
        team.members.each do |member|
          3.times { project.merge_requests << create(:merge_request, assignee: member) }
        end
      end
    end

    Then 'I should see merge requests from this team assigned to me' do
      team = UserTeam.last
      team.projects.each do |project|
        team.members.each do |member|
          project.issues.assigned(member).each do |merge_request|
            page.should have_content merge_request.title
          end
        end
      end
    end

    Given 'I have new user "John"' do
      create :user, name: "John"
    end

    When 'I visit team people page' do
      team = UserTeam.last
      visit team_members_path(team)
    end

    And 'I select user "John" from list with role "Reporter"' do
      user = User.find_by_name("John")
      within "#team_members" do
        select user.name, :from => "user_ids"
        select "Reporter", :from => "default_project_access"
      end
      click_button "Add"
    end

    Then 'I should see user "John" in team list' do
      user = User.find_by_name("John")
      team_members_list = find(".team-table")
      team_members_list.should have_content user.name
    end

    And 'I have my own project without teams' do
      @project = create :project, namespace: current_user.namespace
    end

    And 'I visit my team page' do
      team = UserTeam.where(owner_id: current_user.id).last
      visit team_path(team)
    end

    When 'I click on link "Projects"' do
      click_link "Projects"
    end

    And 'I click link "Assign project to Team"' do
      click_link "Assign project to Team"
    end

    Then 'I should see form with my own project in avaliable projects list' do
      projects_select = find("#project_ids")
      projects_select.should have_content(@project.name)
    end

    When 'I submit form with selected project and max access' do
      within "#assign_projects" do
        select @project.name_with_namespace, :from => "project_ids"
        select "Reporter", :from => "greatest_project_access"
      end
      click_button "Add"
    end

    Then 'I should see my own project in team projects list' do
      projects = find(".projects-table")
      projects.should have_content(@project.name)
    end

    When 'I click link "New Team Member"' do
      click_link "New Team Member"
    end

  protected

  def current_team
    @user_team ||= UserTeam.first
  end

  def project
    current_team.projects.first
  end

  def assigned_to_user key, user
    project.send(key).where(assignee_id: user)
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
