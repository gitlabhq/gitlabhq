class Spinach::Features::ProjectTeamManagement < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include Select2Helper

  step 'I should be able to see myself in team' do
    expect(page).to have_content(@user.name)
    expect(page).to have_content(@user.username)
  end

  step 'I should see "Dmitriy" in team list' do
    user = User.find_by(name: "Dmitriy")
    expect(page).to have_content(user.name)
    expect(page).to have_content(user.username)
  end

  step 'I select "Mike" as "Reporter"' do
    user = User.find_by(name: "Mike")

    page.within ".users-project-form" do
      select2(user.id, from: "#user_ids", multiple: true)
      select "Reporter", from: "access_level"
    end
    click_button "Add users to project"
  end

  step 'I should see "Mike" in team list as "Reporter"' do
    user = User.find_by(name: 'Mike')
    project_member = project.project_members.find_by(user_id: user.id)
    page.within "#project_member_#{project_member.id}" do
      expect(page).to have_content('Mike')
      expect(page).to have_content('Reporter')
    end
  end

  step 'I select "sjobs@apple.com" as "Reporter"' do
    page.within ".users-project-form" do
      select2("sjobs@apple.com", from: "#user_ids", multiple: true)
      select "Reporter", from: "access_level"
    end
    click_button "Add users to project"
  end

  step 'I should see "sjobs@apple.com" in team list as invited "Reporter"' do
    project_member = project.project_members.find_by(invite_email: 'sjobs@apple.com')
    page.within "#project_member_#{project_member.id}" do
      expect(page).to have_content('sjobs@apple.com')
      expect(page).to have_content('Invited')
      expect(page).to have_content('Reporter')
    end
  end

  step 'I should see "Dmitriy" in team list as "Developer"' do
    user = User.find_by(name: 'Dmitriy')
    project_member = project.project_members.find_by(user_id: user.id)
    page.within "#project_member_#{project_member.id}" do
      expect(page).to have_content('Dmitriy')
      expect(page).to have_content('Developer')
    end
  end

  step 'I change "Dmitriy" role to "Reporter"' do
    project = Project.find_by(name: "Shop")
    user = User.find_by(name: 'Dmitriy')
    project_member = project.project_members.find_by(user_id: user.id)
    page.within "#project_member_#{project_member.id}" do
      click_button 'Edit'
      select "Reporter", from: "member_access_level_#{project_member.id}"
      click_button "Save"
    end
  end

  step 'I should see "Dmitriy" in team list as "Reporter"' do
    user = User.find_by(name: 'Dmitriy')
    project_member = project.project_members.find_by(user_id: user.id)
    page.within "#project_member_#{project_member.id}" do
      expect(page).to have_content('Dmitriy')
      expect(page).to have_content('Reporter')
    end
  end

  step 'I should not see "Dmitriy" in team list' do
    user = User.find_by(name: "Dmitriy")
    expect(page).not_to have_content(user.name)
    expect(page).not_to have_content(user.username)
  end

  step 'gitlab user "Mike"' do
    create(:user, name: "Mike")
  end

  step 'gitlab user "Dmitriy"' do
    create(:user, name: "Dmitriy")
  end

  step '"Dmitriy" is "Shop" developer' do
    user = User.find_by(name: "Dmitriy")
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

  step 'I click cancel link for "Dmitriy"' do
    project = Project.find_by(name: "Shop")
    user = User.find_by(name: 'Dmitriy')
    project_member = project.project_members.find_by(user_id: user.id)
    page.within "#project_member_#{project_member.id}" do
      click_link('Remove user from project')
    end
  end

  step 'I share project with group "OpenSource"' do
    project = Project.find_by(name: 'Shop')
    os_group = create(:group, name: 'OpenSource')
    create(:project, group: os_group)
    @os_user1 = create(:user)
    @os_user2 = create(:user)
    os_group.add_owner(@os_user1)
    os_group.add_user(@os_user2, Gitlab::Access::DEVELOPER)
    share_link = project.project_group_links.new(group_access: Gitlab::Access::MASTER)
    share_link.group_id = os_group.id
    share_link.save!
  end

  step 'I should see "Opensource" group user listing' do
    expect(page).to have_content("Shared with OpenSource group, members with Master role (2)")
    expect(page).to have_content(@os_user1.name)
    expect(page).to have_content(@os_user2.name)
  end
end
