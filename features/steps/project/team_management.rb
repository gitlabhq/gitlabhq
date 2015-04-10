class Spinach::Features::ProjectTeamManagement < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include Select2Helper

  step 'I should be able to see myself in team' do
    page.should have_content(@user.name)
    page.should have_content(@user.username)
  end

  step 'I should see "Sam" in team list' do
    user = User.find_by(name: "Sam")
    page.should have_content(user.name)
    page.should have_content(user.username)
  end

  step 'I click link "Add members"' do
    find(:css, 'button.btn-new').click
  end

  step 'I select "Mike" as "Reporter"' do
    user = User.find_by(name: "Mike")

    within ".users-project-form" do
      select2(user.id, from: "#user_ids", multiple: true)
      select "Reporter", from: "access_level"
    end
    click_button "Add users to project"
  end

  step 'I should see "Mike" in team list as "Reporter"' do
    within ".access-reporter" do
      page.should have_content('Mike')
    end
  end

  step 'I select "sjobs@apple.com" as "Reporter"' do
    within ".users-project-form" do
      select2("sjobs@apple.com", from: "#user_ids", multiple: true)
      select "Reporter", from: "access_level"
    end
    click_button "Add users to project"
  end

  step 'I should see "sjobs@apple.com" in team list as invited "Reporter"' do
    within ".access-reporter" do
      page.should have_content('sjobs@apple.com')
      page.should have_content('invited')
      page.should have_content('Reporter')
    end
  end

  step 'I should see "Sam" in team list as "Developer"' do
    within ".access-developer" do
      page.should have_content('Sam')
    end
  end

  step 'I change "Sam" role to "Reporter"' do
    project = Project.find_by(name: "Shop")
    user = User.find_by(name: 'Sam')
    project_member = project.project_members.find_by(user_id: user.id)
    within "#project_member_#{project_member.id}" do
      click_button "Edit access level"
      select "Reporter", from: "project_member_access_level"
      click_button "Save"
    end
  end

  step 'I should see "Sam" in team list as "Reporter"' do
    within ".access-reporter" do
      page.should have_content('Sam')
    end
  end

  step 'I click link "Remove from team"' do
    click_link "Remove from team"
  end

  step 'I should not see "Sam" in team list' do
    user = User.find_by(name: "Sam")
    page.should_not have_content(user.name)
    page.should_not have_content(user.username)
  end

  step 'gitlab user "Mike"' do
    create(:user, name: "Mike")
  end

  step 'gitlab user "Sam"' do
    create(:user, name: "Sam")
  end

  step '"Sam" is "Shop" developer' do
    user = User.find_by(name: "Sam")
    project = Project.find_by(name: "Shop")
    project.team << [user, :developer]
  end

  step 'I own project "Website"' do
    @project = create(:empty_project, name: "Website", namespace: @user.namespace)
    @project.team << [@user, :master]
  end

  step '"Mike" is "Website" reporter' do
    user = User.find_by(name: "Mike")
    project = Project.find_by(name: "Website")
    project.team << [user, :reporter]
  end

  step 'I click link "Import team from another project"' do
    click_link "Import members from another project"
  end

  When 'I submit "Website" project for import team' do
    project = Project.find_by(name: "Website")
    select project.name_with_namespace, from: 'source_project_id'
    click_button 'Import'
  end

  step 'I click cancel link for "Sam"' do
    project = Project.find_by(name: "Shop")
    user = User.find_by(name: 'Sam')
    project_member = project.project_members.find_by(user_id: user.id)
    within "#project_member_#{project_member.id}" do
      click_link('Remove user from team')
    end
  end
end
