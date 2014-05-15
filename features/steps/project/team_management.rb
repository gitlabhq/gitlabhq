class ProjectTeamManagement < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include Select2Helper

  Then 'I should be able to see myself in team' do
    page.should have_content(@user.name)
    page.should have_content(@user.username)
  end

  And 'I should see "Sam" in team list' do
    user = User.find_by(name: "Sam")
    page.should have_content(user.name)
    page.should have_content(user.username)
  end

  Given 'I click link "New Team Member"' do
    click_link "New project member"
  end

  And 'I select "Mike" as "Reporter"' do
    user = User.find_by(name: "Mike")

    select2(user.id, from: "#user_ids", multiple: true)
    within "#new_team_member" do
      select "Reporter", from: "project_access"
    end
    click_button "Add users"
  end

  Then 'I should see "Mike" in team list as "Reporter"' do
    within ".access-reporter" do
      page.should have_content('Mike')
    end
  end

  Given 'I should see "Sam" in team list as "Developer"' do
    within ".access-developer" do
      page.should have_content('Sam')
    end
  end

  And 'I change "Sam" role to "Reporter"' do
    user = User.find_by(name: "Sam")
    within "#user_#{user.id}" do
      select "Reporter", from: "team_member_project_access"
    end
  end

  And 'I should see "Sam" in team list as "Reporter"' do
    within ".access-reporter" do
      page.should have_content('Sam')
    end
  end

  And 'I click link "Remove from team"' do
    click_link "Remove from team"
  end

  And 'I should not see "Sam" in team list' do
    user = User.find_by(name: "Sam")
    page.should_not have_content(user.name)
    page.should_not have_content(user.username)
  end

  And 'gitlab user "Mike"' do
    create(:user, name: "Mike")
  end

  And 'gitlab user "Sam"' do
    create(:user, name: "Sam")
  end

  And '"Sam" is "Shop" developer' do
    user = User.find_by(name: "Sam")
    project = Project.find_by(name: "Shop")
    project.team << [user, :developer]
  end

  Given 'I own project "Website"' do
    @project = create(:empty_project, name: "Website", namespace: @user.namespace)
    @project.team << [@user, :master]
  end

  And '"Mike" is "Website" reporter' do
    user = User.find_by(name: "Mike")
    project = Project.find_by(name: "Website")
    project.team << [user, :reporter]
  end

  And 'I click link "Import team from another project"' do
    click_link "Import members from another project"
  end

  When 'I submit "Website" project for import team' do
    project = Project.find_by(name: "Website")
    select project.name_with_namespace, from: 'source_project_id'
    click_button 'Import'
  end

  step 'I click cancel link for "Sam"' do
    within "#user_#{User.find_by(name: 'Sam').id}" do
      click_link('Remove user from team')
    end
  end
end
